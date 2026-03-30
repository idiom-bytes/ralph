You are planning tasks for @IMPLEMENTATION_PLAN.md. Follow this protocol exactly.

RULES — read these before doing anything:
- Plan only. Do NOT implement anything.
- Do NOT assume functionality is missing — confirm with code search first.
- Every task MUST have acceptance criteria. A task without criteria is incomplete.
- Acceptance criteria must be observable and verifiable — not "it works" but specific outcomes.

PROTOCOL:

0. ORIENT
   Read @RALPH.md and @IMPLEMENTATION_PLAN.md (if present).
   Explore the full codebase using up to 500 parallel subagents.

1. ANALYZE
   Compare the codebase against the project goal in @RALPH.md.
   Search for: TODO, minimal implementations, placeholders, skipped/flaky tests, inconsistent patterns.
   Use @IMPLEMENTATION_PLAN.md to determine what is already complete or in progress.

2. PLAN
   Create or update @IMPLEMENTATION_PLAN.md as a prioritized bullet list.
   Use extended thinking to prioritize — what unblocks the most progress?
   Each task MUST follow this format:

   - [ ] Task description (what needs to be done)
     - [ ] Acceptance criterion (specific verifiable outcome)
     - [ ] Acceptance criterion (edge case or constraint)
     - [ ] Acceptance criterion (what must NOT break)

   Example:
   - [ ] Users can register and update their profile
     - [ ] Empty form submission shows validation errors
     - [ ] Duplicate email returns clear error message
     - [ ] Users cannot change email after registration
     - [ ] Profile updates persist across sessions

   Bad criteria (do not write these):
   - [ ] Registration works
   - [ ] Tests pass
   - [ ] Code is clean

3. REVIEW
   Walk through each task and confirm:
   a. Does it have at least 2 acceptance criteria?
   b. Are the criteria specific and verifiable (not vague)?
   c. Is the task scoped to one logical unit of work?
   If not, fix it before finishing.

ULTIMATE GOAL: [YOUR GOAL HERE]. Consider missing elements and plan accordingly. If you identify a gap, search first to confirm it doesn't exist, then document it with acceptance criteria in @IMPLEMENTATION_PLAN.md.
