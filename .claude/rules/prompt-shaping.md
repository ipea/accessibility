# Prompt Shaping (standing habit)

**When a request is informal, dictated or ambiguous, shape it silently before
acting.** Resolve:

1. **Role:** whose expertise answers this (R package maintainer, data.table
   performance engineer, transport-accessibility methodologist, technical
   writer)?
2. **Task:** the single concrete deliverable, as verb + object.
3. **Context:** which functions, tests, fixtures, issues and prior decisions
   (`MEMORY.md`, plans) bear on it.
4. **Constraints:** conventions, gates, CRAN, back-compat, performance.
5. **Output:** a diff, a plan, a report, a benchmark?
6. **Bookend:** at the end, restate the goal and confirm it was met.

Don't narrate this back. Ask (briefly, via `AskUserQuestion`) only when a
decision belongs to the user. Otherwise infer, and state the assumption in one
line.
