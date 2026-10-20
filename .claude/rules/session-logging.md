# Session Logging

**Location:** `quality_reports/session_logs/YYYY-MM-DD_description.md`
(local, gitignored). **Template:** `templates/session-log.md`.

A Stop hook also appends a mechanical change list to
`quality_reports/session_logs/auto/YYYY-MM-DD_auto.md`. The narrative log below is still Claude's job.

## Three triggers (all proactive)

1. **After plan approval:** goal, approach, rationale, key context, and a
   link to the plan.
2. **Incrementally:** append 1–3 lines when a design decision is made, a
   problem is solved, the user corrects something (also add a `[LEARN]` entry
   to `MEMORY.md`), or the approach changes. Don't batch.
3. **End of session:** summary, gate results (actual numbers: tests passed,
   check E/W/N), open questions, next steps.

Record benchmark results (`bench::mark` output) in the log when a performance
claim is made.
