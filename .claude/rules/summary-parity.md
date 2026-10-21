---
paths:
  - "NEWS.md"
  - "README.Rmd"
  - "vignettes/**"
  - "DESCRIPTION"
  - "cran-comments.md"
  - "R/**/*.R"
---

# Summary–body parity

**When editing a summary, re-check the whole summary against what it
summarises.** Don't patch just the flagged word. Summaries drift when the body
changes and the summary isn't re-verified.

**Summaries in this repo:**
- the `Description:` field in `DESCRIPTION`
- the README introduction and section ledes
- vignette introductions
- the opening of each `NEWS.md` version entry
- `cran-comments.md`
- PR titles and `## Summary` blocks
- roxygen `@description` / title lines

## Protocol

1. Read the full body (the function's actual behaviour, the full NEWS section,
   the vignette).
2. List every claim in the summary: counts, function names, "now supports X",
   "no longer Y".
3. Check each claim against the code or body.
4. Rewrite the paragraph as a whole when any claim fails.
5. If the same summary is flagged twice in a row, rewrite it structurally and
   prefer fewer enumerative claims. A summary with no counts can't drift.
