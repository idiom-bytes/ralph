# Ralph-Codex

Templated Ralph-Wiggum autonomous loop. Supports Claude and Codex with firejail sandboxing.

Methodology: https://github.com/ghuntley/how-to-ralph-wiggum

## Structure

- `loop.sh` — State machine: SNAPSHOT → EXECUTE → VERIFY → COMMIT/ROLLBACK. Runs agent in firejail, verifies independently via `RALPH_VERIFY` env var, only commits+pushes if verification passes. Rolls back on failure.
- `ralph/PROMPT_build.md` — Build mode: pick top task, verify acceptance criteria exist, implement, validate.
- `ralph/PROMPT_plan.md` — Plan mode: gap-analyze codebase against goals, generate tasks with acceptance criteria.
- `ralph/RALPH.md` — Project goal + operational guide: build/test/lint commands, codebase patterns. Keep brief (~60 lines).
- `ralph/IMPLEMENTATION_PLAN.md` — Tasks + acceptance criteria. Each task has checkboxes for both implementation and verification. Disposable — regenerate with plan mode.

## Configuring a Ralph Loop

1. Drop `ralph/` and `loop.sh` into the target project root
2. `ralph/RALPH.md`: set project goal + build/test/lint commands
3. `ralph/PROMPT_plan.md`: replace `[YOUR GOAL HERE]`
4. Run `./loop.sh plan 3` to generate tasks with acceptance criteria
5. Run `RALPH_VERIFY="pytest && ruff check" ./loop.sh` to start building

## loop.sh

```
./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]
```

- Defaults: claude, build, firejail sandbox, unlimited iterations
- `RALPH_VERIFY` — test/lint command run after agent, before commit. Empty = trust agent.
- `RALPH_AGENT`, `CLAUDE_MODEL` (default: opus), `CODEX_MODEL` (default: o3)
- Halts after 3 consecutive failures (`MAX_CONSECUTIVE_FAILURES`)
