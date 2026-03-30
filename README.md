# ralph-codex

Templated [Ralph-Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) setup for autonomous AI development loops. Supports Claude and Codex, sandboxed with firejail.

## Usage

1. Drop `ralph/` and `loop.sh` into your project root
2. Edit `ralph/RALPH.md` — set your project goal + build/test commands
3. Edit `ralph/PROMPT_plan.md` — set your ultimate goal
4. `./loop.sh plan 3` then `./loop.sh`

```
./loop.sh [claude|codex] [plan|build] [max_iterations] [--no-sandbox]
```

## What's in the box

```
loop.sh                          # Ralph loop (claude/codex, firejail, plan/build)
ralph/
├── PROMPT_build.md              # Build mode prompt
├── PROMPT_plan.md               # Planning mode prompt
├── RALPH.md                     # Project goal + build commands (Ralph maintains)
└── IMPLEMENTATION_PLAN.md       # Tasks + acceptance criteria (Ralph maintains)
```

## Learn more

https://github.com/ghuntley/how-to-ralph-wiggum
