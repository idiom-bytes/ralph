# ralph-codex

Templated [Ralph-Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) setup for autonomous AI development loops. Supports Claude and Codex, sandboxed with firejail.

## Usage

1. Drop `ralph/` and `loop.sh` into your project root
2. Edit `ralph/RALPH.md` — set your project goal + build/test commands
3. Edit `ralph/PROMPT_plan.md` — set your ultimate goal
4. `./loop.sh plan 3` then `./loop.sh`

```bash
# Basic usage
./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]

# With verification gate (recommended)
RALPH_VERIFY="pytest && mypy ." ./loop.sh
```

## What's in the box

```
loop.sh                          # Ralph loop (SNAPSHOT → EXECUTE → VERIFY → COMMIT/ROLLBACK)
ralph/
├── PROMPT_build.md              # Build mode prompt
├── PROMPT_plan.md               # Planning mode prompt
├── RALPH.md                     # Project goal + build commands (Ralph maintains)
└── IMPLEMENTATION_PLAN.md       # Tasks + acceptance criteria (Ralph maintains)
```

## Loop states

Each iteration: **SNAPSHOT → EXECUTE → VERIFY → COMMIT or ROLLBACK**

1. **SNAPSHOT** — record HEAD before the agent runs
2. **EXECUTE** — run the agent (claude/codex) in a firejail sandbox
3. **VERIFY** — run `RALPH_VERIFY` command independently (if set)
4. **COMMIT + PUSH** — if verify passes (or not set), commit and push
5. **ROLLBACK** — if verify fails, discard all agent changes, try again

Set `RALPH_VERIFY` to enable the verification gate. Without it, the loop trusts the agent.

Halts after 3 consecutive verification failures (configurable via `MAX_CONSECUTIVE_FAILURES`).

## Learn more

https://github.com/ghuntley/how-to-ralph-wiggum
