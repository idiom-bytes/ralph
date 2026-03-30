#!/bin/bash
# Ralph Loop — runs Claude or Codex iteratively on a research/build task
# Supports firejail sandboxing to limit blast radius of autonomous agents.
#
# Usage: ./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]
# Examples:
#   ./loop.sh                    # Claude, build mode, sandboxed, unlimited
#   ./loop.sh 20                 # Claude, build mode, sandboxed, 20 iterations
#   ./loop.sh plan               # Claude, plan mode, sandboxed, unlimited
#   ./loop.sh codex build 10     # Codex, build mode, sandboxed, 10 iterations
#   ./loop.sh --no-sandbox       # Claude, build mode, NO sandbox, unlimited
#   RALPH_AGENT=codex ./loop.sh  # Codex via env var

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

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# ─── Agent config ───────────────────────────────────────────────────────────
CLAUDE_MODEL="${CLAUDE_MODEL:-opus}"
CODEX_MODEL="${CODEX_MODEL:-o3}"

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project:  $(basename "$PROJ_DIR")"
echo "Mode:     $MODE"
echo "Prompt:   $(basename "$PROMPT_FILE")"
echo "Branch:   $CURRENT_BRANCH"
echo "Sandbox:  $SANDBOX"
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
            --output-format=stream-json \
            --model $CLAUDE_MODEL \
            --verbose"
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
run_sandboxed() {
    local cmd="$1"

    if [ "$SANDBOX" = false ]; then
        eval "$cmd"
        return $?
    fi

    firejail \
        --noprofile \
        --quiet \
        --whitelist="$PROJ_DIR" \
        --whitelist="$HOME/.config" \
        --read-only="$HOME/.config" \
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
        --read-only="$HOME/.local" \
        --whitelist="$HOME/.gitconfig" \
        --read-only="$HOME/.gitconfig" \
        --whitelist="$HOME/.ssh" \
        --read-only="$HOME/.ssh" \
        --whitelist="$HOME/.cache" \
        --noroot \
        --caps.drop=all \
        --nonewprivs \
        --seccomp \
        --env=PATH="$HOME/.local/bin:$HOME/.nvm/versions/node/$(node -v 2>/dev/null || echo v22)/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        -- bash -c "$cmd"
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

    run_sandboxed "$AGENT_CMD" || {
        echo "Agent iteration $ITERATION failed; continuing..."
    }

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" 2>/dev/null || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH" || true
    }

    echo "Iteration $ITERATION complete."
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph loop finished after $ITERATION iterations."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
