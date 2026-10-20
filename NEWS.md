# accessibility (development version)

## New features

- `cumulative_interval()` has a new argument `fill_missing_ids`. When `TRUE`
  (the default), origins (or destinations) that cannot reach any opportunity
  within the interval are included in the output with an accessibility of 0,
  as in `cumulative_cutoff()`. Previously they were dropped from the output.

## Bug fixes

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
  `travel_matrix` are now treated as unreachable, and ids missing from
  `land_use_data` raise an informative error.
- Fixed a bug in `theil_t()` in which observations with no access were
  wrongly handled: without `socioeconomic_groups` they were excluded from the
  index (but not from the average accessibility), and with
  `socioeconomic_groups` they made the index `NaN`. They now contribute 0 to
  the index, following the usual `0 * log(0) = 0` convention. `group_by`
  levels in which no one has access are now kept in the output with `NA`,
  instead of being dropped.
- Fixed two bugs in `balancing_cost()`: origins only balanced when they reached
  more opportunities than people (instead of as many opportunities as people),
  and origins that balanced at a cost greater than the last multiple of
  `cost_increment` were reported as `NA`. `cost_increment` must now be greater
  than 0.
- Fixed a bug in `spatial_availability()` in which an `NA` demand in
  `land_use_data` made every result `NA`, even when the id with the `NA` was
  not in `travel_matrix`.
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

## Minor changes

- Accessibility, inequality and poverty functions now raise an error if
  `land_use_data` or `sociodemographic_data` contain duplicated ids.
  Previously, only one of the duplicated rows was silently used.

## Notes

- Updated the package website and GitHub URLs after the repository moved from
  the `ipeaGIT` to the `ipea` organization.

# accessibility 1.5.0

## New features

- New function `constrained_accessibility()`, which implements the family of 
constrained accessibility measures proposed in Soukhov et al. (2025).

## Minor changes

- The function `fgt_poverty()` has a new argument `poor_below_threshold`. when
set to `TRUE` (default,) the observations below the poverty line are considered 
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
  When aggregation by origin-destination pair, the output also includes the
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

The package has been to tremendous changes. Basically, there's not a single
part of it that remained untouched: documentation, vignettes, function names,
parameter names, extra functionality, performance improvements, etc. While it
is impossible to highlight everything that has been done, we'll try to summary
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
