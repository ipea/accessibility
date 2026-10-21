# accessibility (development version)

## New features

- `cumulative_interval()` has a new argument `fill_missing_ids`. When `TRUE`
  (the default), origins (or destinations) that cannot reach any opportunity
  within the interval are included in the output with an accessibility of 0,
  as in `cumulative_cutoff()`. Previously they were dropped from the output.

## Breaking changes

- `cumulative_interval()` now returns the summary of the accessibility levels
  as a `numeric` without truncation (e.g. the median of 26 and 27
  opportunities is 26.5). Previously, results were truncated to integers.
- `concentration_index(type = "corrected")` now calculates the correction
  factor with the bounds of the whole accessibility distribution, instead of
  the bounds of each `group_by` group, so groups are corrected on a common
  scale. Results only change when `group_by` is used.
- Accessibility functions now treat `NA` values in `land_use_data`
  (opportunities, demand and supply) and ids of `travel_matrix` missing from
  `land_use_data` as 0, and their warnings say so. Previously, such a value
  made the results of every id that reached it `NA`, except when
  `fill_missing_ids = TRUE` had to fill other missing ids, in which case
  those `NA` results became 0. When every value is `NA`, results are now the
  same as when every value is 0 (which can be `NaN`).

## Bug fixes

- Fixed a bug in `cumulative_interval()` in which some cutoffs were left out
  of the summary when `interval_increment` produced cutoffs with floating
  point noise (e.g. `interval_increment = 0.1`, whose fourth cutoff is
  `0.30000000000000004`).
- Fixed a bug in `balancing_cost()` in which numeric ids (e.g. `101`, `102`)
  were used as positions to look up each origin's population, which resulted
  in `NA` or wrong balancing costs.
- Fixed a bug in `spatial_availability()` in which a destination that no one
  could reach (or that was only reached by origins with no demand) made the
  results of every origin `NaN`. The opportunities in such destinations are
  now left unallocated.
- Fixed a bug in `gini_index()`, `concentration_index()` and `theil_t()` in
  which large integer opportunity and population counts overflowed when
  multiplied, returning `NA` (e.g. with long travel time cutoffs or large
  cities).
- Fixed a bug in `constrained_accessibility(constraint = "doubly")` in which
  the impedance matrix and the demand and supply totals were aligned by row
  position instead of by id. Results were only correct when `travel_matrix`
  listed every origin-destination pair ordered by destination and
  `land_use_data` was ordered like the travel matrix. Pairs missing from
  `travel_matrix` are now treated as unreachable.
- Fixed a bug in `theil_t()` in which observations with no access were
  wrongly handled: without `socioeconomic_groups` they were excluded from the
  index (but not from the average accessibility), and with
  `socioeconomic_groups` they made the index `NaN`. They now contribute 0 to
  the index, following the usual `0 * log(0) = 0` convention. `group_by`
  levels in which no one has access are now kept in the output with `NA`,
  instead of being dropped.
- Fixed a bug in `spatial_availability()` in which an `NA` demand in
  `land_use_data` made every result `NA`, even when the id with the `NA` was
  not in `travel_matrix`.
- Fixed two bugs in `balancing_cost()`: origins only balanced when they reached
  more opportunities than people (instead of as many opportunities as people),
  and origins that balanced at a cost greater than the last multiple of
  `cost_increment` were reported as `NA`. `cost_increment` must now be greater
  than 0.
- Fixed a bug in `constrained_accessibility(constraint = "doubly")` in which
  a small constant added to the balancing factors distorted the results when
  impedance weights were very small (e.g. with steep decay functions or long
  travel costs). The function now also warns when the balancing procedure
  stops before reaching `error_threshold`.
- Fixed a bug in `constrained_accessibility()` (`constraint = "total"` or
  `"singly"`) in which `fill_missing_ids = TRUE` raised an error ("Object
  'access' not found") when `group_by` left an origin/destination and group
  combination missing from the results.
- Fixed a bug in `concentration_index()` in which observations with the same
  income received different fractional ranks, so the result depended on the
  order of the rows (especially with ordinal variables such as income
  deciles). Tied observations now share the same rank, the midpoint of their
  block in the cumulative population distribution.
- Fixed a bug in `cumulative_interval()` in which, when several intervals
  were passed to `interval`, each interval was summarised over the cutoffs of
  every interval within its range, so its result depended on the other
  intervals requested (e.g. `c(0, 20)` together with `c(5, 15)`).
- Fixed a bug in `cumulative_interval()` in which the upper limit of the
  interval was not considered when the interval width was not a multiple of
  `interval_increment` (e.g. `interval = c(0, 25)` with
  `interval_increment = 10`).
- Fixed a bug in `cumulative_cutoff()` in which cutoffs with floating point
  noise (e.g. created with `seq(0, 0.5, by = 0.1)`) could have their results
  replaced by 0 when filling missing ids. Travel cost columns with
  non-syntactic names (e.g. `"bus fare"`) now also work.

- Fixed a bug in `palma_ratio()` in which the income cutoffs depended on the
  scale of the population weights, which resulted in `NA` when population was
  given as shares (e.g. summing to 1).
- Fixed a bug in `concentration_index(type = "corrected")` in which the index
  was `NaN` when everyone had the same accessibility. It's now 0, as with
  `type = "standard"`.
- `fgt_poverty()` now raises an error if `poverty_line` is not a single finite
  number (or is 0 when `poor_below_threshold = FALSE`) and if
  `poor_below_threshold` is not a single `TRUE` or `FALSE`. Previously these
  inputs silently returned recycled values, `NA` or `Inf`, or a cryptic error.
- Fixed a bug in `palma_ratio()` in which, with more than one `group_by`
  column, the output included rows with `NA` for group combinations that were
  not present in the data. The output is also no longer keyed.

- Fixed a bug in `decay_stepped()` that emitted a warning for each `NA`
  travel cost (the weight is still `NA`).
- Fixed a bug in `constrained_accessibility(constraint = "total")` that added
  a data.table index attribute to the user's `land_use_data`.

- Fixed a bug in `constrained_accessibility(constraint = "doubly")` that
  returned a `data.table` when `travel_matrix` was a `data.frame` (or another
  class), instead of keeping the class of the input.

## Minor changes

- Accessibility, inequality and poverty functions now raise an error if
  `land_use_data` or `sociodemographic_data` contain duplicated ids.
  Previously, only one of the duplicated rows was silently used.
- Accessibility functions now raise an error if a `travel_cost` column of
  `travel_matrix` contains negative values, which previously produced weights
  above 1 and inflated accessibility levels.
- Accessibility functions now raise a clear error when the ids of
  `travel_matrix` and `land_use_data` have incompatible types (e.g. integer
  and character), instead of an obscure join error.
- `decay_linear()` now requires `cutoff` to be greater than 0 (a cutoff of 0
  produced `NaN` weights).
- `decay_logistic()` and `decay_stepped()` now raise an error when given
  duplicated parameter combinations, which produced duplicated results.
- `constrained_accessibility()` now checks that `demand` and `supply` are
  single strings.
- Results of accessibility functions are no longer returned as keyed
  data.tables when missing ids are filled (previously, they were keyed only in
  this case).
- Opportunities, demand, supply, population and income are now matched to
  the input data by id with `match()` instead of an update join. Accessibility
  functions are about 1.2 to 3.3 times faster and use about half the memory on
  large travel matrices, with identical results. If `travel_matrix` already
  has a column named like the opportunity column, that column is now fully
  replaced by the values in `land_use_data`.
- The functions created by `decay_logistic()` and `decay_stepped()` are now
  vectorised instead of looping over each travel cost, which makes them about
  50 and 200 times faster on large travel matrices, with identical results.
- The functions created by `decay_exponential()`, `decay_power()` and
  `decay_logistic()` now calculate each weight once per unique travel cost
  when costs are repeated (e.g. rounded travel times), which makes them about
  2 to 6 times faster, with identical results.
- `gravity()` and `floating_catchment_area()` are faster, especially with
  several decay function values (e.g. `gravity()` with three values is about 4
  times faster on large travel matrices), because the travel matrix is no
  longer copied once per value and sums are optimized by `{data.table}`.
  Results may differ from previous versions by floating point rounding only
  (relative differences below 1e-14). `gravity()` with integer opportunities
  and `decay_binary()` no longer fails when accessibility exceeds the largest
  integer.
- `constrained_accessibility(constraint = "doubly")` is about 2 to 4 times
  faster and uses much less memory on large travel matrices, because the
  balancing factors are now calculated with matrix products instead of loops
  over origins and destinations. Results may differ from previous versions by
  floating point rounding only.
- `spatial_availability()` is about 2 times faster on large travel matrices,
  because its balancing factors are now calculated with sums optimized by
  `{data.table}`. Results may differ from previous versions by floating point
  rounding only.
- `cost_to_closest()` is about 1.3 to 2.3 times faster, especially with
  several values of `n`, because the travel matrix is now filtered and sorted
  only once, with identical results.
- `cumulative_cutoff()` (with several cutoffs of a single travel cost),
  `cumulative_interval()` and `balancing_cost()` are much faster on large
  travel matrices (e.g. about 10 times with 30 cutoffs, 4 times with an
  interval of 40 minutes and 6 to 20 times with `cost_increment = 0.1`),
  because the opportunities are summed once by travel cost instead of once
  per cutoff, so their running time and memory barely depend on the number of
  cutoffs. With non-integer opportunities, results may differ from previous
  versions by floating point rounding. In `cumulative_cutoff()` and
  `cumulative_interval()`, integer accessibility levels larger than the
  largest integer are now returned as doubles, instead of raising an error
  when only some ids exceeded it.
  `cumulative_interval()` now returns its rows sorted by interval, id and
  `group_by` columns in every case.
- Errors and warnings raised by the package now use `{cli}`, with consistent
  formatting of argument names and values. Long lists of ids or columns in
  messages are abbreviated. `{cli}` and `{rlang}` are new dependencies.

- `fgt_poverty()` now warns when `poor_below_threshold = FALSE` and
  `accessibility_data` contains `Inf` values (e.g. from `cost_to_closest()` for
  origins that can't reach the required opportunities), which make FGT1 and
  FGT2 infinite. The documentation and the inequality and poverty vignette now
  explain this case, and the vignette includes an example with
  `poor_below_threshold = FALSE`.

## Notes

- Updated the package website and GitHub URLs after the repository moved from
  the `ipeaGIT` to the `ipea` organization.
- Vignettes and tests now only use the suggested packages `{sf}`,
  `{ggplot2}` and `{tibble}` when they are installed.

# accessibility 1.5.0

## New features

- New function `constrained_accessibility()`, which implements the family of 
constrained accessibility measures proposed in Soukhov et al. (2025).

## Minor changes

- The function `fgt_poverty()` has a new argument `poor_below_threshold`. When
set to `TRUE` (default) the observations below the poverty line are considered 
to be poor. This is the correct approach for primal accessibility measures (e.g.
cumulative accessibility). If `FALSE`, then observations above the poverty line 
are considered to be poor. This is the correct approach for dual accessibility 
measures (e.g. travel time to the closest facility). When set to `FALSE`, FGT 1 
and 2 do not have an upper bound. Closes [#63](https://github.com/ipea/accessibility/issues/63)



# accessibility 1.4.0

## Bug fixes

- Fixed a bug in which land use data passed to accessibility functions as a
  `tibble` could lead to an error.

## New features

- New function `decay_logistic()`.

## Notes

- Package description has been adjusted to better reflect the current set of
  available features.

# accessibility 1.3.0

## New features

- New parameter `detailed_results` to `spatial_availability()`, used to specify
  whether results should be aggregated by origin-destination pair or by origin.
  When aggregating by origin-destination pair, the output also includes the
  demand, impedance and combined balancing factors used to calculate spatial
  availability.

# accessibility 1.2.0

## New features

- New inequality functions `concentration_index()` and `theil_t()`.

## Notes

- Various documentation tweaks.
- Testing performance has greatly improved.

# accessibility 1.1.0

## New features

- The package now includes functions to estimate accessibility inequalities
  (`palma_ratio()` and `gini_index()`) and poverty (`fgt_poverty()`).
- New accessibility functions `spatial_availability()` and `balancing_cost()`.
- New vignette "Calculating accessibility inequality and poverty".
- `cost_to_closest()` parameter `n` now accepts a numeric vector, instead of
  being restricted to a single number.
- `cumulative_cutoff()` parameters `cutoff` and `travel_cost` now accepts a
  numeric and a character vector, respectively, instead of being restricted to
  a single number/string.
- `cumulative_interval()` parameter `interval` now accepts a list of numeric
  vectors, instead of being restricted to a single vector.
- The decay functions can now take numeric vectors as input, instead of being
  restricted to a single number (in the case of `decay_stepped()`, both `steps`
  and `weights` can take a `list` of `numeric` vectors as input, instead of
  being restricted to a single `numeric` vector each).

## Notes

- Various documentation tweaks.
- Added the new accessibility functions to the intro vignette.

# accessibility 1.0.1

## Bug fixes

- Fixed a bug in which `cost_to_closest()` would return `NA` values when
  filling missing ids (which should be filled with `Inf`, since they cannot
  reach any opportunities). This was also responsible for the warning reported
  in #27, which was also fixed.

# accessibility 1.0.0

The package has been through tremendous changes. Basically, there's not a single
part of it that remained untouched: documentation, vignettes, function names,
parameter names, extra functionality, performance improvements, etc. While it
is impossible to highlight everything that has been done, we'll try to summarize
some of the key points in the following topics.

## Breaking changes

- Accessibility functions previously worked with a single input dataset:
  `data`. Now they require two input datasets: `travel_matrix` and
  `land_use_data`.
- Function names were changed:
  - `time_to_closest()` -> `cost_to_closest()`
  - `cumulative_time_cutoff()` -> `cumulative_cutoff()`
  - `cumulative_time_interval()` -> `cumulative_interval()`
  - `gravity_access()` -> `gravity()`
- Parameter names were changed:
  - `opportunity_col` -> `opportunity`
  - `travel_cost_col` -> `travel_cost`
  - `by_col` -> `active`
  - In `cost_to_closest()`: `n_opportunities` -> `n`
  - In `cumulative_interval()`: `stat` -> `summary_function`
  - In `floating_catchment_area()`: `population_col` -> `demand`
  - In `floating_catchment_area()`: `fca_metric` -> `method`
- Parameter required values were changed:
  - `active` now takes a `logical`, instead of a string (which `by_col`
    previously took).
  - In `cumulative_interval()`: `summary_function` now takes a `function`,
    instead of a string (which `stat` previously took).

## New features

- New function `decay_stepped()`.
- New parameter `interval_increment` to `cumulative_interval()`, used to
  specify how many travel cost units separate the cutoffs used to calculate the
  accessibility estimates which will be used to calculate the summary estimate
  within the specified interval.
- All accessibility functions gained a `group_by` parameter, that allows
  accessibility estimates to be grouped by one or more columns present in
  `travel_matrix`.
- All accessibility functions (but `cumulative_interval()`) gained a
  `fill_missing_ids` parameter, that includes in the results origins whose
  accessibility would be 0 but, due to some commonly overlooked implementation
  details, are usually left out from the output. `cumulative_interval()` doesn't
  have this parameter because its result will always include all origins,
  otherwise the summary measure wouldn't be calculated properly.

# accessibility 0.1.0

- Initial CRAN release.
