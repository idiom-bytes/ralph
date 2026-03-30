You are planning tasks for the implementation plan. Follow this protocol exactly.

RULES — read these before doing anything:
- Plan only. Do NOT implement anything.
- Do NOT assume functionality is missing — confirm with code search first.
- Every task MUST have acceptance criteria. A task without criteria is incomplete.
- Acceptance criteria must be observable and verifiable — not "it works" but specific outcomes.

PROTOCOL:

0. ORIENT
   Read the files `ralph/RALPH.md` and `ralph/IMPLEMENTATION_PLAN.md` (if present).
   Explore the full codebase to understand the current state.

1. ANALYZE
   Compare the codebase against the project goal in `ralph/RALPH.md`.
   Search for: TODO, minimal implementations, placeholders, skipped/flaky tests, inconsistent patterns.
   Use `ralph/IMPLEMENTATION_PLAN.md` to determine what is already complete or in progress.

2. PLAN
   Create or update `ralph/IMPLEMENTATION_PLAN.md` as a prioritized list.
   Prioritize in this order:
   1. Architectural decisions and core abstractions (these stay forever — get them right first)
   2. Integration points between modules (where things connect breaks first)
   3. Unknowns and spike work (de-risk before building on assumptions)
   4. Standard features and implementation
   5. Polish, cleanup, and quick wins (last — never before the hard stuff)
   Use this exact hierarchy — every level is a `- [ ]` checkbox:

   - [ ] Goal
     - [ ] Epic
       - [ ] Task
         - [ ] Acceptance criterion
         - [ ] Acceptance criterion

   Example:
   - [ ] User authentication system
     - [ ] User registration
       - [ ] Implement registration endpoint
         - [ ] Empty form returns 400 with validation errors
         - [ ] Duplicate email returns 409 with clear message
         - [ ] Successful registration returns 201 with user ID
       - [ ] Implement email verification
         - [ ] Verification email sent within 5 seconds of registration
         - [ ] Expired token returns 410 with re-send option

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

ULTIMATE GOAL: [YOUR GOAL HERE]. Consider missing elements and plan accordingly. If you identify a gap, search first to confirm it doesn't exist, then document it with acceptance criteria in `ralph/IMPLEMENTATION_PLAN.md`.
