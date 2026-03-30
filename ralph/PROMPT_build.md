0a. Study the project by reading @RALPH.md and @IMPLEMENTATION_PLAN.md.
0b. Explore the codebase using parallel Sonnet subagents to understand the current state.

1. Choose the most important task from @IMPLEMENTATION_PLAN.md. Before making changes, search the codebase (don't assume not implemented) using Sonnet subagents. You may use up to 500 parallel Sonnet subagents for searches/reads and only 1 Sonnet subagent for build/tests. Use Opus subagents when complex reasoning is needed (debugging, architectural decisions).
2. If the task has no acceptance criteria, add them before implementing. Every task must have observable acceptance criteria that prove correctness — not just "it works" but specific behaviors, edge cases, and constraints.
3. Implement the task. If functionality is missing then it's your job to add it per the project goal in @RALPH.md. Ultrathink.
4. Verify EVERY acceptance criterion for the task. Run the build/test/lint commands from @RALPH.md. A task is not done until all criteria checkboxes AND all mechanical checks pass.
5. When all checks pass, check off the completed criteria and task in @IMPLEMENTATION_PLAN.md, then `git add -A` then `git commit` with a message describing the changes. After the commit, `git push`.

99999. Important: When authoring documentation, capture the why — tests and implementation importance.
999999. Important: Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
9999999. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1 if 0.0.0 does not exist.
99999999. You may add extra logging if required to debug issues.
999999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts. Update especially after finishing your turn.
9999999999. When you learn something new about how to run the application, update @RALPH.md using a subagent but keep it brief.
99999999999. For any bugs you notice, resolve them or document them in @IMPLEMENTATION_PLAN.md using a subagent even if it is unrelated to the current piece of work.
999999999999. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
9999999999999. When @IMPLEMENTATION_PLAN.md becomes large periodically clean out completed items using a subagent.
99999999999999. If you find inconsistencies between code and the project goal in @RALPH.md, use an Opus subagent with 'ultrathink' to update @RALPH.md.
999999999999999. IMPORTANT: Keep @RALPH.md operational only — status updates and progress notes belong in `IMPLEMENTATION_PLAN.md`. A bloated RALPH.md pollutes every future loop's context.
