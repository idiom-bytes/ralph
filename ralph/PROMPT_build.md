You are executing ONE task from @IMPLEMENTATION_PLAN.md. Follow this protocol exactly.

RULES — read these before doing anything:
- Implement ONLY one task per iteration. Do not combine tasks.
- Do NOT skip acceptance criteria. Every criterion must be verified.
- Do NOT remove or weaken existing acceptance criteria.
- Do NOT mark a task done unless every criterion checkbox is checked.
- Do NOT git commit or push — the loop handles that after independent verification.
- Search the codebase before implementing — do not assume functionality is missing.
- Implement completely. No placeholders, no stubs, no "TODO later".

PROTOCOL:

0. ORIENT
   Read @RALPH.md and @IMPLEMENTATION_PLAN.md.
   Explore the codebase using up to 500 parallel subagents.

1. SELECT
   Pick the highest-priority incomplete task (3rd-level unchecked `- [ ]`) from @IMPLEMENTATION_PLAN.md.
   Tasks are nested under goals and epics: Goal → Epic → Task → Acceptance Criteria.
   State which task you selected and why.
   If the task has no acceptance criteria (4th-level checkboxes), STOP and add them before doing anything else.

2. INVESTIGATE
   Search the codebase for existing implementations related to this task.
   Do not assume it is missing — confirm with code search first.
   Use subagents for searches/reads. Use extended thinking for complex reasoning.

3. IMPLEMENT
   Make the changes required for this ONE task.
   If functionality is missing, add it per the project goal in @RALPH.md.

4. VERIFY
   For EACH acceptance criterion under the task, do the following:
   a. Run the specific check that proves this criterion is met.
   b. Confirm it passes.
   c. Check off the criterion in @IMPLEMENTATION_PLAN.md.
   Then run ALL build/test/lint commands from @RALPH.md.
   Do not check off the task until every criterion AND every mechanical check passes.

5. UPDATE
   Check off the task in @IMPLEMENTATION_PLAN.md.
   Add any learnings or discoveries as notes.
   If you found bugs unrelated to this task, document them as new tasks with acceptance criteria.

ONGOING RULES:
- Keep @RALPH.md operational and brief (~60 lines). Status updates go in @IMPLEMENTATION_PLAN.md.
- When you learn something new about how to build/run the project, update @RALPH.md.
- When @IMPLEMENTATION_PLAN.md grows large, clean out completed items.
- If tests unrelated to your task fail, fix them as part of this iteration.
- If you find inconsistencies between code and @RALPH.md, update @RALPH.md.
