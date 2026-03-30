0a. Study the project by reading @RALPH.md and @IMPLEMENTATION_PLAN.md (if present).
0b. Explore the full codebase using up to 500 parallel Sonnet subagents to understand the current state.

1. Compare the current codebase against the project goal in @RALPH.md. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted by priority. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

2. Every task MUST have acceptance criteria — observable behaviors that prove correctness. Not "it works" but specific verifiable outcomes, edge cases, and constraints. Example:
   - [ ] Users can register and update their profile
     - [ ] Empty form submission shows validation errors
     - [ ] Duplicate email returns clear error message
     - [ ] Users cannot change email after registration
   A task without acceptance criteria is incomplete planning. Ralph will drift without them.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first.

ULTIMATE GOAL: [YOUR GOAL HERE]. Consider missing elements and plan accordingly. If you identify a gap, search first to confirm it doesn't exist, then document it with acceptance criteria in @IMPLEMENTATION_PLAN.md using a subagent.
