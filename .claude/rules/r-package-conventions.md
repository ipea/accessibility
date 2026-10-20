---
paths:
  - "R/**/*.R"
  - "tests/**/*.R"
  - "man/**"
  - "vignettes/**"
  - "README.Rmd"
  - "DESCRIPTION"
  - "NAMESPACE"
  - "NEWS.md"
  - "_pkgdown.yml"
  - "inst/REFERENCES.bib"
---

# accessibility package conventions

**Standard:** a CRAN-ready, fast, predictable package whose numbers are right.
`R CMD check --as-cran` returns 0 errors, 0 warnings, and only explained notes.
New code reads like the code around it.

Part A describes how accessibility is written today (verified against the
source, 2026-10-12). Items tagged **[NEW]** are decisions for new or modified
code only; never apply them to untouched code as drive-bys. Part B is the
general CRAN standard. When they conflict, Part A wins; flag the conflict in
the plan.

---

# Part A: accessibility house style

## A1. Namespacing

- **Always call `package::function()`**, including `data.table::`,
  `checkmate::`, `stats::`, `utils::`, `Hmisc::`.
- **Exceptions:**
  - data.table special symbols and operators: `:=`, `.I`, `.SD`, `%chin%`,
    `.GRP`, `.N`. These, plus `utils globalVariables` and `Rdpack reprompt`,
    are the only `@importFrom` imports (in `R/accessibility-package.R`).
    `.()` is used inside `[` and is covered by `globalVariables(".")`.
  - ggplot2 functions in vignettes and README, after `library(ggplot2)`.
- Never use `library()`/`require()` in `R/`. Suggested packages (`sf`,
  `ggplot2`, `tibble`) are guarded with `requireNamespace("pkg", quietly =
  TRUE)`.
- Column names used with non-standard evaluation go into the
  `utils::globalVariables(c(...))` block in `R/accessibility-package.R`.
  Append new names at the end and check for duplicates first.

## A2. Function skeleton

Every accessibility measure follows the same shape (see
`R/cumulative_cutoff.R`, `R/gravity.R`):

```r
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @template group_by
#' @template active
#' @template fill_missing_ids_combinations
#' @template return_accessibility
#' @family <family>
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' ...
#' @export
some_measure <- function(travel_matrix,
                         land_use_data,
                         opportunity,
                         travel_cost,
                         group_by = character(0),
                         active = TRUE,
                         fill_missing_ids = TRUE) {

  checkmate::assert_string(opportunity)
  checkmate::assert_logical(active, len = 1, any.missing = FALSE)
  assert_group_by(group_by)                                  # R/assert_and_assign.R
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(land_use_data, travel_matrix, opportunity, active = active)

  # if not a dt, keep original class to assign later when returning result

  if (!inherits(travel_matrix, "data.table")) {
    original_class <- class(travel_matrix)
    data <- data.table::as.data.table(travel_matrix)
  } else {
    data <- data.table::copy(travel_matrix)
  }

  # ... body ...

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}
```

- **Inputs:** validate with `checkmate::assert_*` first, then the shared
  `assert_*()` helpers in `R/assert_and_assign.R` (`assert_travel_matrix`,
  `assert_land_use_data`, `assert_accessibility_data`,
  `assert_sociodemographic_data`, `assert_group_by`,
  `assert_access_group_by`, `assert_decay_function`, `assert_cutoff`). Reuse
  them rather than writing new checks. Enumerated string options use
  `checkmate::assert_string()` + `checkmate::assert_names(x, subset.of = ...)`
  (or `assert_choice()` when exactly one value is ever valid).
- **Input data contracts** (documented in `man/roxygen/templates/`):
  - `travel_matrix`: `from_id`, `to_id`, the `travel_cost` columns, the
    `group_by` columns.
  - `land_use_data`: `id` plus the `opportunity`/`demand`/`supply` columns.
  - `accessibility_data` (inequality/poverty): `id` plus `opportunity` and
    `group_by`.
  - `sociodemographic_data`: `id` plus `population` (and `income` where used).
  - `group_by` can never contain `from_id`/`to_id` (access) or `id`
    (inequality).
- **Output class mirrors input:** a `data.table` in returns a `data.table`; a
  `data.frame`/`tibble` in returns that class, via the `original_class` idiom
  above. Every measure has a test for it.
- **Output columns:** `id`, then `group_by` columns, then any grid columns
  (cutoffs, `decay_function_arg`), then the opportunity column named after
  `opportunity`. Sorted with `data.table::setorderv()` by those keys.
- **Data-quality warnings, not errors:** ids in `travel_matrix` missing from
  `land_use_data`, NA in opportunity/demand columns, and extra columns in
  `travel_matrix` not in `travel_cost`/`group_by` (`warn_extra_cols()`) all
  `warning()` and continue. Keep that contract.
- **`fill_missing_ids`:** origins with no reachable opportunity are absent
  after aggregation; when `TRUE` they are filled with 0 via
  `do_fill_missing_ids()` (`R/fill_missing_ids.R`). New measures that can drop
  ids expose the same argument.

## A3. data.table discipline

- **Never modify the caller's objects.** The input `travel_matrix` is
  `data.table::copy()`ed (or converted with `as.data.table()`, which copies)
  before `merge_by_reference()` adds the opportunity column. Any new `:=` /
  `data.table::set*()` must act on a table the function owns. Every measure has
  an "input data sets remain unchanged" test.
- `land_use_data` is only converted, never updated by reference; keep it that
  way (`merge_by_reference()` only reads from it, matching on `id` with
  `match()`/`chmatch()`; it relies on the `assert_*()` helpers rejecting
  duplicated ids).
- data.table auto-indexing may add an `index` attribute to the caller's table
  after `dt[i]`. Tests clear it with `data.table::setindex(x, NULL)` before
  comparing; that is accepted, don't add `copy()` calls to prevent it.
- Use `:=` for in-place updates of owned tables; `%chin%` for character
  membership; `get()` / `..var` / `eval()` with an explicit `env` for
  programmatic column names (see `cumulative_cutoff()`).
- Long calls are split one argument per line; `[` blocks put the empty `i`
  on its own line:
  ```r
  cum_opps <- cum_opps[
    ,
    .(access = sum(get(.opportunity_colname))),
    by = eval(groups, envir = env)
  ]
  ```
- End data.table returns with `[]` (`return(access[])`) so the result prints
  after `:=`.
- No row-wise loops or `apply` over rows of the travel matrix. Iteration over
  *parameter grids* (cutoffs, decay values) with `mapply`/`lapply` +
  `data.table::rbindlist()` is the established pattern.

## A4. Messages and errors

- The package's own messages use `cli::cli_abort(<msg>, call = NULL)` and
  `cli::cli_warn(<msg>)` (cli and rlang are Imports; migrated 2026-10-20).
  Inline markup: `{.arg x}` for arguments and `df$col` expressions,
  `{.val {x}}` for values/vectors, `{.code}` for code, `{.cls}` for classes;
  bullets (`"*"`, `"i"`) instead of `
`. Runtime values always go through
  interpolation, never `paste0()` into the template. Input type errors still
  come from checkmate.
- cli wraps long messages at the console width, so test `regexp`s that span
  several words use `[[:space:]]+` between them.
- **Deprecations:** keep the old argument for at least one CRAN release with a
  `cli::cli_warn()` naming the replacement, and test it with
  `expect_warning()`.

## A5. Style

- 2-space indent, `<-`, 80-column lines, snake_case, explicit `return()` at
  the end of exported functions; validators end with
  `return(invisible(TRUE))`.
- Function arguments aligned one per line under the opening parenthesis when
  they don't fit on one line.
- Two blank lines between top-level functions in multi-function files
  (`assert_and_assign.R`). Comments are lowercase prose explaining *why*,
  followed by a blank line before the code they describe.
- There is no `.lintr` in this repo; run `lintr::lint()` with defaults and
  treat only lints on **changed lines** as actionable.
- Internal helpers: descriptive snake_case names, `#' @keywords internal`
  roxygen stub (or none, as in `fill_missing_ids.R`; match the file).

## A6. Documentation (roxygen2, markdown, Rdpack)

- Shared parameters use the templates in `man/roxygen/templates/`
  (`@template travel_matrix`, `land_use_data`, `opportunity`, `travel_cost`,
  `group_by`, `active`, `decay_function`, `demand`, `supply`, `population`,
  `accessibility_data`, `return_accessibility`, …). Add a template only when a
  parameter is shared by 3+ functions. Edit the template, not each `.Rd`.
- `@family` tags in use: `cumulative access`, `decay functions`,
  `Floating catchment area`, `Constrained accessibility`, `inequality`. Match
  the exact spelling (case matters for grouping).
- **Citations** use Rdpack: entries in `inst/REFERENCES.bib`, cited with
  `\insertCite{key;textual}{accessibility}` and listed under
  `@references \insertAllCited{}`. Every measure cites the paper it
  implements. New bib entries need DOI/URL checked.
- **Examples** use the bundled fixtures in `inst/extdata/` and are gated so
  they don't run on CRAN:
  ```r
  #' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
  #' data_dir <- system.file("extdata", package = "accessibility")
  #' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
  #' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
  ```
  Tests and vignettes set `Sys.setenv(OMP_THREAD_LIMIT = 2)` for CRAN CPU
  time.
- Every new export is added to a section of `_pkgdown.yml` (Accessibility,
  Decay functions, Inequality, Poverty). Check with `pkgdown::check_pkgdown()`.
- Never hand-edit generated files. Edit the source and regenerate:

  | Generated file | Regenerate with |
  |---|---|
  | `NAMESPACE`, `man/*.Rd` | `devtools::document()` |
  | `README.md` | `rmarkdown::render("README.Rmd")` |
  | `codemeta.json` | `codemetar::write_codemeta()` (synced from DESCRIPTION) |
  | `inst/extdata/*.rds` | scripts in `data-raw/` (never edit the `.rds` directly) |

## A7. Tests (testthat, 2nd edition)

- `DESCRIPTION` has no `Config/testthat/edition`, so tests run in the 2nd
  edition (`expect_is()` is used widely). Don't switch editions as a
  drive-by; that changes `expect_equal()` semantics across the suite.
- Shared fixtures live in `tests/testthat/setup.R`: `travel_matrix` (with a
  `mode` column, two copies), `smaller_matrix` (first 10 rows),
  `land_use_data`, `pareto_frontier` / `small_frontier` (multi-cost),
  `small_access`. Running a test file manually needs
  `source("tests/testthat/setup.R")` first.
- One file per function: `tests/testthat/test-<function>.R`, with a
  `tester()` wrapper that sets defaults, then `test_that()` blocks.
- **New or modified measures need the standard block set** (see
  `test-cumulative_cutoff.R`):
  - "raises errors due to incorrect input" (every argument, including
    missing required columns)
  - "throws warning if travel_matrix has an extra col"
  - "returns a dataframe whose class is the same as travel_matrix's"
  - "result has correct structure" (columns, types, row count)
  - **"input data sets remain unchanged"** (clear indices with
    `data.table::setindex(x, NULL)` first)
  - "... is correctly calculated" against **hand-computed values** on a few
    selected ids, or a tiny synthetic matrix (as in
    `test-constrained-wrapper.R`). Never assert only on the current output.
  - "works even if travel_matrix and land_use has specific colnames"
    (columns named like internal variables)
  - `fill_missing_ids` behaviour, where the argument exists
- Restore global state with `on.exit()`. `withr` is not a dependency.
- `tests/test_rafa/` is a personal scratch folder, not part of the suite.

## A8. Correctness and performance

- **Results must match the cited formula.** When implementing or changing a
  measure, write the formula (with the paper's notation) in the plan, and test
  against a hand-computed toy example. For constrained/balancing measures
  check the marginals (row/column sums equal demand/supply) and convergence.
- Decay functions return a function of `travel_cost` that yields one numeric
  weight per element (a named list of vectors when several decay values are
  given); weights are in `[0, 1]` and non-increasing in cost. Keep that
  contract; `assert_decay_function()` relies on it.
- Inequality/poverty measures weight by `population`; NA handling is tested
  ("handles missing data correctly"). State `na.rm` explicitly in new code.
- Avoid materialising the full cutoff × OD grid when a join or cumulative sum
  would do. **A claimed speed-up needs evidence:** `bench::mark(old = ...,
  new = ...)` on the bundled `travel_matrix` (and a larger matrix when
  relevant), results checked equal, timings recorded in the plan or session
  log. `bench` is a dev tool, not a dependency.
- Don't add a hard dependency (Imports) without a plan that justifies it.

## A9. NEWS.md

Entries go under `# accessibility (development version)` (create it above the
latest release heading when missing). Section headings used in the repo:
`## New features`, `## Bug fixes`, `## Minor changes`, `## Notes`, and
`## Breaking changes` only for changes that break code or change correct
results.

```
- New function `fun()`, which implements ... proposed in Author et al. (Year).
- `fun()` has a new argument `arg` ... Closes [#63](https://github.com/ipea/accessibility/issues/63).
- Fixed a bug in `fun()` that ... (#issue).
```

Function names in backticks; link issues; credit external contributors.

## A10. Figures (vignettes, README, pkgdown)

- **Existing convention:** ggplot2 and sf are in Suggests; vignette chunks
  gated on `requireNamespace()`. Maps use `inst/extdata/grid_bho.rds`.
- **[NEW] Publication-ready standard for new or modified figures:** one
  consistent theme, a colour-blind-safe palette (viridis / Okabe-Ito),
  labelled axes with units, fixed `fig.width`/`fig.height`/`dpi`. Existing
  figures are restyled only through a plan.

---

# Part B: general CRAN standard

- **DESCRIPTION:** `Imports` for code in `R/`, `Suggests` for
  tests/vignettes/optional paths, `Depends` only for the R version. Version
  floors only when a feature requires them. `Authors@R` with roles.
- **Docs:** every export documents all `@param`s, `@return`, and runnable
  `@examples`. Use `\donttest{}` / `@examplesIf` for slow-but-correct
  examples; never use `\dontrun{}` to hide errors.
- **Red flags:**

| Red flag | Do instead |
|---|---|
| `library()`/`require()` in `R/` | `pkg::fun()` |
| Writing outside `tempdir()` | Write only to `tempdir()` or user-supplied paths |
| `<<-` to global env | Return values |
| `print()`/`cat()` in functions | `cli::cli_inform()`/`cli::cli_warn()`, gated on a `verbose` arg where relevant |
| `options()`/`par()`/threads changed, not restored | `on.exit(..., add = TRUE)` |
| `T`/`F` | `TRUE`/`FALSE` |
| Unvalidated enumerated arg | `checkmate::assert_names(x, subset.of = ...)` |
| `==` on doubles | `abs(x - y) < tol` or `all.equal()` |
| [NEW] Implicit `na.rm` | State `na.rm` explicitly in new or modified code |
| Growing vectors in loops | Pre-allocate or vectorise |

- **Versioning:** dev versions use `x.y.z.9000`. The maintainer bumps release
  versions; Claude never does.

## Checklist (new or modified code)

```
[ ] pkg::fun() everywhere (except data.table operators / ggplot2 in docs)
[ ] checkmate + shared assert_*() helpers; group_by can't hold reserved id cols
[ ] input travel_matrix / land_use_data not modified (copy()); test proves it
[ ] output class mirrors travel_matrix (original_class idiom); test proves it
[ ] output columns/order follow A2; fill_missing_ids where ids can drop
[ ] values tested against a hand-computed toy example / the cited formula
[ ] cli::cli_abort(call = NULL)/cli::cli_warn() with inline markup
[ ] style: 2 spaces, <-, 80 cols, return(), file's blank-line style
[ ] roxygen: shared @template, @family (exact spelling), @return,
    @examplesIf NOT_CRAN, Rdpack citation for the method
[ ] new exports listed in _pkgdown.yml; new NSE names in globalVariables()
[ ] devtools::document() run; no hand-edited generated files
[ ] NEWS.md bullet for user-facing changes
[ ] perf claims backed by bench::mark with equal results
```

## Cross-references

- [`quality-gates.md`](quality-gates.md): when each check must pass.
- `.claude/agents/r-package-reviewer.md` enforces this rule. It is local to
  the maintainer's setup and may be absent in a fresh clone; if so, apply the
  checklist manually.
