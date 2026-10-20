# CLAUDE.md — accessibility

**accessibility** is an R package of fast, convenient functions for transport
accessibility analysis. Given a pre-computed travel cost matrix and land use
data, it calculates accessibility levels (cumulative, gravity, floating
catchment area, spatial availability, balancing cost, constrained measures,
cost to closest), decay functions, and accessibility inequality and poverty
(Palma, concentration, Gini, Theil T, FGT). Built on `data.table`. Published
on CRAN; developed by Ipea (ipeaGIT). Maintainer: Daniel Herszenhut; authors
include Rafael H. M. Pereira and Anastasia Soukhov. License MIT. Docs:
<https://ipeagit.github.io/accessibility/>.

---

## Core principles

- **Correct numbers first.** Every measure implements a published formula
  (cited via Rdpack). A new or changed measure is tested against a
  hand-computed toy example, not just against its own current output.
- **Performance is a feature.** Vectorised `data.table` code, no avoidable
  copies. Any claimed speed-up needs a `bench::mark()` comparison with equal
  results checked.
- **Never surprise the caller.** Functions never modify the input
  `travel_matrix` / `land_use_data`, and the output class mirrors the input
  (`data.table`, `data.frame`, `tibble`).
- **CRAN-ready at all times.** `R CMD check --as-cran`: 0 errors, 0 warnings.
- **Plan first.** Enter plan mode before non-trivial tasks. Every plan must be
  reviewed by two adversarial agents that improve it and make it simpler, with
  as little code intervention as possible. Present the plan only when both
  agents reach consensus (max 3 rounds, then escalate the disagreement). Plans
  live in `quality_reports/plans/`.
- **Verify after.** Every task ends with the gates below, not with "should work".
- **Learn from corrections.** Log `[LEARN:category] wrong → right` in
  `MEMORY.md`.
- **Code style.** Always use the convention `package::function()`. Exceptions
  are functions from ggplot2 and special data.table operators such as `:=`.

Conventions are in [`.claude/rules/r-package-conventions.md`](.claude/rules/r-package-conventions.md);
gates are in [`.claude/rules/quality-gates.md`](.claude/rules/quality-gates.md).

---

## Repository map

```
accessibility/
├── DESCRIPTION, NAMESPACE        # NAMESPACE is roxygen-generated; never hand-edit
├── R/                            # one exported function per file, plus:
│   ├── accessibility-package.R   # package doc, importFrom, utils::globalVariables()
│   ├── assert_and_assign.R       # shared input validators (assert_travel_matrix, ...)
│   ├── merge_by_reference.R      # joins land use opportunities onto the (copied) matrix
│   ├── fill_missing_ids.R        # fills unreachable ids with 0
│   ├── warn_extra_cols.R         # warns about columns not in travel_cost/group_by
│   └── apply_gravity_measure.R   # shared by gravity-based measures
├── tests/testthat/               # test-<function>.R; fixtures built in setup.R
├── tests/test_rafa/              # personal scratch scripts, not part of the suite
├── inst/extdata/                 # travel_matrix.rds, land_use_data.rds, pareto_frontier.rds, grid_bho.rds
├── inst/REFERENCES.bib           # Rdpack citations used in the docs
├── data-raw/                     # scripts that regenerate inst/extdata
├── man/roxygen/templates/        # shared @param/@return templates
├── vignettes/                    # accessibility.Rmd, decay_functions.Rmd, inequality_and_poverty.Rmd
├── README.Rmd → README.md        # edit the .Rmd, then re-render
├── NEWS.md                       # user-facing changelog
├── _pkgdown.yml                  # reference index; every export must be listed
├── .github/workflows/            # rcmdcheck matrix, pkgdown, test-coverage
└── .pre-commit-config.yaml       # readme-rendered, codemeta, pkgdown (active only after `pre-commit install`)
```

Function families: accessibility (`cumulative_cutoff`, `cumulative_interval`,
`gravity`, `floating_catchment_area`, `spatial_availability`,
`balancing_cost`, `constrained_accessibility`, `cost_to_closest`) ·
`decay_*` (binary, exponential, linear, logistic, power, stepped) ·
inequality (`concentration_index`, `gini_index`, `palma_ratio`, `theil_t`) ·
poverty (`fgt_poverty`).

Local-only workflow files (gitignored and Rbuildignored): `MEMORY.md`,
`quality_reports/`, `templates/`, and everything in `.claude/` except `rules/`.

---

## Commands

```r
devtools::load_all()
devtools::document()                         # regenerate man/ + NAMESPACE
devtools::test()                             # full suite
devtools::test(filter = "cumulative_cutoff")
source("tests/testthat/setup.R")             # fixtures, when running a test file by hand
devtools::check(args = "--as-cran")          # long; run in background
lintr::lint("R/<file>.R")                    # no .lintr: defaults; act on changed lines only
rmarkdown::render("README.Rmd")              # after editing README.Rmd
pkgdown::build_site()
covr::package_coverage()
```

- CRAN checks CPU time, so threads are capped: tests and vignettes set
  `Sys.setenv(OMP_THREAD_LIMIT = 2)`. Examples run only when
  `NOT_CRAN=true` (`@examplesIf`).
- Tests run in testthat's 2nd edition (no `Config/testthat/edition`).

---

## Quality gates (summary)

| Checkpoint | Must hold |
|---|---|
| Commit | `document()` produces no content drift (`git diff`); tests for touched functions pass; `lintr` clean on changed lines; values checked against a hand-computed example for changed measures; README re-rendered if `README.Rmd` changed; `NEWS.md` entry for user-facing changes |
| PR | Full `test()` passes; `check(--as-cran)` gives 0 errors / 0 warnings, NOTEs triaged; review loop converged; `r-package-reviewer` 0 CRITICAL/MAJOR |
| Release | `/acc-package-check`; win-builder + rhub; reverse-dependency check; `cran-comments.md` updated |

Never bypass `.pre-commit-config.yaml` hooks (`--no-verify`). Details: `.claude/rules/quality-gates.md`.

---

## Skills and agents

These are local to the maintainer's Claude setup and are not in git. In a fresh
clone, follow the rules in `.claude/rules/` directly.

Project skills carry an `acc-` prefix so user-level skills with the same base
name can't shadow them. **In this repo, always use the `acc-` version:** use
`/acc-commit`, never a generic `/commit` that merges to `main`. Where
user-level rules conflict with `.claude/rules/`, the project rules win.

- `/acc-package-check`: document, test, check `--as-cran`, triage, reviewer
  report.
- `/acc-commit`: Gate 1, then branch and commit. Push and PR only when asked,
  after Gate 2. **Merging to `main` only on explicit request.**
- `/acc-diagnose`: root-cause a failing test or wrong accessibility result.
- `/acc-checkpoint`, `/acc-compress-session`, `/context-status`: session state.
- `/acc-learn`: turn a session discovery into a reusable skill.
- Agent `r-package-reviewer`: read-only CRAN and convention review of
  package source.

---

## Working mode

1. **Plan:** for non-trivial tasks, enter plan mode, explore, ask only about
   real decisions, pass the adversarial plan review, and get approval.
2. **Execute (contractor mode):** after approval, work autonomously through
   implement → verify → parallel review → fix, looping until reviews come
   back dry (see `.claude/rules/orchestrator-protocol.md`). Come back only for
   ambiguity or a decision that belongs to the user.
3. **Report:** summarise what changed, gate results, open questions; log the
   session.

No commits, pushes, PRs, merges, version bumps or `.github/workflows/`
changes without an explicit request. Never hand-edit generated files
(`NAMESPACE`, `man/*.Rd`, `README.md`, `codemeta.json`, `inst/extdata/*.rds`).
