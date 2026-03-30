#!/bin/bash
# Ralph Loop — runs Claude or Codex iteratively on a research/build task
# Supports firejail sandboxing to limit blast radius of autonomous agents.
#
# Loop states per iteration:
#   EXECUTE → VERIFY → (pass: COMMIT+PUSH | fail: COMMIT, no push, next iteration fixes it)
#
# Usage: ./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]
# Examples:
#   ./loop.sh                    # Claude, build mode, sandboxed, unlimited
#   ./loop.sh 20                 # Claude, build mode, sandboxed, 20 iterations
#   ./loop.sh plan               # Claude, plan mode, sandboxed, unlimited
#   ./loop.sh codex build 10     # Codex, build mode, sandboxed, 10 iterations
#   ./loop.sh --no-sandbox       # Claude, build mode, NO sandbox, unlimited
#   RALPH_AGENT=codex ./loop.sh  # Codex via env var
#
# WARNING: --no-sandbox disables ALL filesystem protection. The agent can
# read/write anything your user can. Only use for debugging.

set -euo pipefail

# Run from project root (where this script lives); ralph/ is a subdirectory
PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$PROJ_DIR/ralph"
cd "$PROJ_DIR" || exit 1

# Ensure PATH includes user-local tool directories
export PATH="$HOME/.local/bin:$PATH"
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use 2>/dev/null
    NODE_BIN="$(dirname "$(which node 2>/dev/null)" 2>/dev/null)" || true
    [ -n "$NODE_BIN" ] && export PATH="$NODE_BIN:$PATH"
fi

# ─── Parse arguments (order-independent) ────────────────────────────────────
AGENT="${RALPH_AGENT:-claude}"
MODE="build"
MAX_ITERATIONS=0
SANDBOX=true

for arg in "$@"; do
    case "$arg" in
        claude|codex)
            AGENT="$arg"
            ;;
        plan|build)
            MODE="$arg"
            ;;
        --no-sandbox)
            SANDBOX=false
            ;;
        *)
            if [[ "$arg" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS="$arg"
            else
                echo "Error: invalid argument '$arg'"
                echo "Usage: ./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]"
                exit 1
            fi
            ;;
    esac
done

case "$AGENT" in
    claude|codex) ;;
    *)
        echo "Error: unsupported agent '$AGENT' (expected 'claude' or 'codex')"
        exit 1
        ;;
esac

if [ "$MODE" = "plan" ]; then
    PROMPT_FILE="$RALPH_DIR/PROMPT_plan.md"
else
    PROMPT_FILE="$RALPH_DIR/PROMPT_build.md"
fi

# ─── Verify tools ───────────────────────────────────────────────────────────
for cmd in "$AGENT" git; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd not found on PATH"
        echo "PATH=$PATH"
        exit 1
    fi
done

if [ "$SANDBOX" = true ] && ! command -v firejail &>/dev/null; then
    echo "Warning: firejail not found — falling back to --no-sandbox"
    SANDBOX=false
fi

if [ "$SANDBOX" = false ]; then
    echo "WARNING: Running without sandbox — agent has full filesystem access."
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# ─── Agent config ───────────────────────────────────────────────────────────
CLAUDE_MODEL="${CLAUDE_MODEL:-opus}"
CODEX_MODEL="${CODEX_MODEL:-o3}"

# Verification gate: set to your test command to enable
# Example: RALPH_VERIFY="pytest && mypy . && ruff check" ./loop.sh
RALPH_VERIFY="${RALPH_VERIFY:-}"

ITERATION=0
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES="${MAX_CONSECUTIVE_FAILURES:-3}"
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: detached HEAD — checkout a branch before running the loop."
    exit 1
fi

# Resolve node bin path once (for firejail PATH injection)
NODE_BIN_DIR=""
if command -v node &>/dev/null; then
    NODE_BIN_DIR="$(dirname "$(command -v node)")"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project:  $(basename "$PROJ_DIR")"
echo "Mode:     $MODE"
echo "Prompt:   $(basename "$PROMPT_FILE")"
echo "Branch:   $CURRENT_BRANCH"
echo "Sandbox:  $SANDBOX"
[ -n "$RALPH_VERIFY" ] && echo "Verify:   $RALPH_VERIFY"
if [ "$AGENT" = "claude" ]; then
    echo "Agent:    claude -p (--model $CLAUDE_MODEL)"
else
    echo "Agent:    codex exec (--model $CODEX_MODEL)"
fi
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:      $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Build agent command ───────────────────────────────────────────────────
build_agent_cmd() {
    if [ "$AGENT" = "claude" ]; then
        echo "cat '$PROMPT_FILE' | claude -p \
            --dangerously-skip-permissions \
            --model $CLAUDE_MODEL"
    else
        echo "cat '$PROMPT_FILE' | codex exec \
            -m $CODEX_MODEL \
            --dangerously-bypass-approvals-and-sandbox \
            -"
    fi
}

# ─── Firejail wrapper ───────────────────────────────────────────────────────
# With --noprofile, once ANY --whitelist is used, firejail switches to
# whitelist mode: ONLY whitelisted paths are visible under $HOME.
# --read-only must come AFTER its corresponding --whitelist.
#
# Security model:
#   - Project dir: read-write (agent's workspace)
#   - Tool binaries: read-only (claude, codex, node, git)
#   - API keys / configs: read-only
#   - SSH keys: read-only (for git push)
#   - Everything else under $HOME: blocked
run_sandboxed() {
    local cmd="$1"

    if [ "$SANDBOX" = false ]; then
        eval "$cmd"
        return $?
    fi

    # Build PATH for inside the sandbox
    local SANDBOX_PATH="$HOME/.local/bin"
    [ -n "$NODE_BIN_DIR" ] && SANDBOX_PATH="$SANDBOX_PATH:$NODE_BIN_DIR"
    SANDBOX_PATH="$SANDBOX_PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    firejail \
        --noprofile \
        --quiet \
        --whitelist="$PROJ_DIR" \
        --whitelist="$HOME/.claude" \
        --read-only="$HOME/.claude" \
        --whitelist="$HOME/.codex" \
        --read-only="$HOME/.codex" \
        --whitelist="$HOME/.anthropic" \
        --read-only="$HOME/.anthropic" \
        --whitelist="$HOME/.openai" \
        --read-only="$HOME/.openai" \
        --whitelist="$HOME/.nvm" \
        --read-only="$HOME/.nvm" \
        --whitelist="$HOME/.local" \
        --read-only="$HOME/.local/bin" \
        --read-only="$HOME/.local/share/claude" \
        --whitelist="$HOME/.gitconfig" \
        --read-only="$HOME/.gitconfig" \
        --whitelist="$HOME/.ssh" \
        --read-only="$HOME/.ssh" \
        --noroot \
        --caps.drop=all \
        --nonewprivs \
        --seccomp \
        --env=PATH="$SANDBOX_PATH" \
        -- bash -c "$cmd"
}

# ─── Loop stages ───────────────────────────────────────────────────────────

# EXECUTE: Run the agent
execute() {
    echo "[EXECUTE] Running $AGENT..."
    run_sandboxed "$AGENT_CMD" || {
        echo "[EXECUTE] Agent exited non-zero; checking for changes..."
    }
}

# VERIFY: Run verification independently — the agent doesn't grade its own homework
# Returns 0 (pass) or 1 (fail). Failure does NOT rollback — the agent keeps its
# changes and the next iteration can see the failures and fix them.
verify() {
    if [ -z "$RALPH_VERIFY" ]; then
        return 0
    fi

    echo "[VERIFY] Running: $RALPH_VERIFY"
    if eval "$RALPH_VERIFY"; then
        echo "[VERIFY] PASSED"
        return 0
    else
        echo "[VERIFY] FAILED — changes preserved for next iteration to fix"
        return 1
    fi
}

# COMMIT: Stage and commit agent's changes
commit_changes() {
    if git diff --quiet HEAD && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        echo "[COMMIT] No changes to commit."
        return 1
    fi

    git add -A
    git commit -m "ralph: iteration $ITERATION" --allow-empty-message || {
        echo "[COMMIT] Nothing to commit after staging."
        return 1
    }
    echo "[COMMIT] Changes committed."
    return 0
}

# PUSH: Push to remote
push_changes() {
    git push origin "$CURRENT_BRANCH" || {
        echo "[PUSH] Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH" || true
    }
}

# ─── Main loop ──────────────────────────────────────────────────────────────
AGENT_CMD="$(build_agent_cmd)"

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n======================== ITERATION $ITERATION ========================\n"

    # ── EXECUTE ──
    execute

    # ── VERIFY ──
    if verify; then
        # ── COMMIT + PUSH (verification passed) ──
        if commit_changes; then
            push_changes
            CONSECUTIVE_FAILURES=0
            echo "[DONE] Iteration $ITERATION verified and pushed."
        else
            echo "[SKIP] No changes produced in iteration $ITERATION."
            CONSECUTIVE_FAILURES=0
        fi
    else
        # ── COMMIT but don't push (verification failed) ──
        # Keep the changes — next iteration sees the failures and can fix them.
        # This is "let Ralph ralph" — eventual consistency through iteration.
        commit_changes || true
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        echo "[FAIL] Iteration $ITERATION failed verification ($CONSECUTIVE_FAILURES/$MAX_CONSECUTIVE_FAILURES). Changes kept for next iteration."

        if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
            echo "Halting: $MAX_CONSECUTIVE_FAILURES consecutive verification failures."
            break
        fi
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph loop finished after $ITERATION iterations."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
