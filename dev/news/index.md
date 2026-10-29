# Changelog

## accessibility (development version)

### New features

- [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  has a new argument `fill_missing_ids`. When `TRUE` (the default), ids
  that reach no opportunity are kept with accessibility 0, as in
  [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md).

### Breaking changes

- Accessibility functions now treat `NA` opportunity, demand and supply
  values, and `travel_matrix` ids missing from `land_use_data`, as 0.
  Previously, they could make results `NA`.
- Integer opportunity, demand, supply and population columns are now
  converted to doubles, so sums no longer overflow. As a result,
  [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md)
  and
  [`gravity()`](https://ipea.github.io/accessibility/dev/reference/gravity.md)
  (with
  [`decay_binary()`](https://ipea.github.io/accessibility/dev/reference/decay_binary.md))
  return doubles instead of integers when opportunities are integers.
- `concentration_index(type = "corrected")` now uses the bounds of the
  whole accessibility distribution, not of each `group_by` group, to
  calculate the correction factor.
- [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  no longer truncates results to integers (e.g. a median of 26.5).
- `constrained_accessibility(constraint = "doubly")` now always returns
  origin-destination flows and ignores `active` and `detailed_results`.
  Previously, `detailed_results = FALSE` returned the demand and supply
  marginals instead
  ([\#67](https://github.com/ipea/accessibility/issues/67)).

### Bug fixes

- [`balancing_cost()`](https://ipea.github.io/accessibility/dev/reference/balancing_cost.md):
  numeric ids were used as positions to look up population, returning
  `NA` or wrong costs; origins balanced only when opportunities exceeded
  (instead of matched) population; and costs above the last multiple of
  `cost_increment` were `NA`. `cost_increment` must now be greater than
  0.
- [`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md):
  tied incomes now share the same fractional rank, so results no longer
  depend on row order. With `type = "corrected"`, the index is now 0,
  instead of `NaN`, when everyone has the same accessibility.
- [`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md),
  [`gini_index()`](https://ipea.github.io/accessibility/dev/reference/gini_index.md)
  and
  [`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md)
  no longer return `NA` due to integer overflow with large opportunity
  and population counts.
- [`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md):
  - `constraint = "doubly"` aligned impedances and totals by row
    position instead of by id; pairs missing from `travel_matrix` are
    now unreachable.
  - `constraint = "doubly"` no longer adds a constant to the balancing
    factors, which distorted results with very small weights, and now
    warns when balancing stops before reaching `error_threshold`.
  - `constraint = "doubly"` now returns the same class as
    `travel_matrix`.
  - `constraint = "total"` or `"singly"` no longer errors when
    `fill_missing_ids = TRUE` and `group_by` leave combinations missing.
  - `constraint = "total"` no longer adds an index to the user’s
    `land_use_data`.
  - `constraint = "total"`, `"singly"` and `"doubly"` now treat each
    `group_by` combination and each decay value as an independent
    system. Previously, `"total"` split the regional total across
    groups, `"doubly"` balanced all groups as a single system, and all
    three blended several decay values into one result. Detailed results
    now keep the `group_by` and `decay_function_arg` columns
    ([\#66](https://github.com/ipea/accessibility/issues/66),
    [@soukhova](https://github.com/soukhova)).
- [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
  no longer returns `Inf` due to integer overflow with large opportunity
  counts.
- [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md):
  cutoffs with floating point noise (e.g. from `seq(0, 0.5, by = 0.1)`)
  could be zeroed when filling missing ids. Travel cost columns with
  non-syntactic names now work.
- [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md):
  cutoffs with floating point noise (e.g. from
  `interval_increment = 0.1`) were left out of the summary.
- [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md)
  no longer warns for each `NA` travel cost.
- [`palma_ratio()`](https://ipea.github.io/accessibility/dev/reference/palma_ratio.md):
  income cutoffs depended on the scale of population (`NA` with
  population shares), and with several `group_by` columns the output
  included `NA` rows for absent combinations. The output is no longer
  keyed.
- [`spatial_availability()`](https://ipea.github.io/accessibility/dev/reference/spatial_availability.md):
  a destination no one could reach made all results `NaN`. Its
  opportunities are now left unallocated.
- [`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md):
  observations with no access are now included and contribute 0
  (`0 * log(0) = 0`), instead of being excluded or making the index
  `NaN`. `group_by` levels where no one has access are kept with `NA`.

### Minor changes

- Errors and warnings now use [cli](https://cli.r-lib.org).
  [cli](https://cli.r-lib.org) and [rlang](https://rlang.r-lib.org) are
  new dependencies.
- Accessibility, inequality and poverty functions now raise an error if
  `land_use_data` or `sociodemographic_data` have duplicated ids.
- Accessibility functions:
  - raise an error on negative travel costs and a clear error when the
    id types of `travel_matrix` and `land_use_data` are incompatible.
  - match land use data by id with
    [`match()`](https://rdrr.io/r/base/match.html), making them about
    1.2 to 3.3 times faster with half the memory. A `travel_matrix`
    column named like the opportunity column is now replaced.
  - no longer return keyed data.tables when filling missing ids.
- Several functions are faster on large travel matrices. Results may
  differ from previous versions by floating point rounding only.
- [`balancing_cost()`](https://ipea.github.io/accessibility/dev/reference/balancing_cost.md),
  [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md)
  and
  [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  are about 4 to 20 times faster, because opportunities are summed once
  per travel cost instead of once per cutoff.
- [`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md)
  checks that `demand` and `supply` are single strings. With
  `constraint = "doubly"`, it is about 2 to 4 times faster and uses much
  less memory.
- [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
  is about 1.3 to 2.3 times faster.
- [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  always sorts rows by interval, id and `group_by`.
- [`decay_exponential()`](https://ipea.github.io/accessibility/dev/reference/decay_exponential.md),
  [`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md),
  [`decay_power()`](https://ipea.github.io/accessibility/dev/reference/decay_power.md)
  and
  [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md)
  are about 2 to 200 times faster.
- [`decay_linear()`](https://ipea.github.io/accessibility/dev/reference/decay_linear.md)
  requires `cutoff` greater than 0.
- [`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md)
  and
  [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md)
  raise an error on duplicated parameter combinations.
- [`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)
  raises an error on invalid `poverty_line` or `poor_below_threshold`,
  and warns when `poor_below_threshold = FALSE` and `accessibility_data`
  has `Inf` values (e.g. from
  [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)).
- [`floating_catchment_area()`](https://ipea.github.io/accessibility/dev/reference/floating_catchment_area.md)
  and
  [`gravity()`](https://ipea.github.io/accessibility/dev/reference/gravity.md)
  are faster with several decay values (about 4 times with three).
- [`spatial_availability()`](https://ipea.github.io/accessibility/dev/reference/spatial_availability.md)
  is about 2 times faster.

### Notes

- Updated URLs after the repository moved from `ipeaGIT` to `ipea`.

## accessibility 1.5.0

CRAN release: 2026-05-12

### New features

- New function
  [`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md),
  which implements the family of constrained accessibility measures
  proposed in Soukhov et al. (2025).

### Minor changes

- The function
  [`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)
  has a new argument `poor_below_threshold`. When set to `TRUE`
  (default) the observations below the poverty line are considered to be
  poor. This is the correct approach for primal accessibility measures
  (e.g. cumulative accessibility). If `FALSE`, then observations above
  the poverty line are considered to be poor. This is the correct
  approach for dual accessibility measures (e.g. travel time to the
  closest facility). When set to `FALSE`, FGT 1 and 2 do not have an
  upper bound. Closes
  [\#63](https://github.com/ipea/accessibility/issues/63)

## accessibility 1.4.0

CRAN release: 2024-03-06

### Bug fixes

- Fixed a bug in which land use data passed to accessibility functions
  as a `tibble` could lead to an error.

### New features

- New function
  [`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md).

### Notes

- Package description has been adjusted to better reflect the current
  set of available features.

## accessibility 1.3.0

CRAN release: 2023-10-20

### New features

- New parameter `detailed_results` to
  [`spatial_availability()`](https://ipea.github.io/accessibility/dev/reference/spatial_availability.md),
  used to specify whether results should be aggregated by
  origin-destination pair or by origin. When aggregating by
  origin-destination pair, the output also includes the demand,
  impedance and combined balancing factors used to calculate spatial
  availability.

## accessibility 1.2.0

CRAN release: 2023-09-21

### New features

- New inequality functions
  [`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md)
  and
  [`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md).

### Notes

- Various documentation tweaks.
- Testing performance has greatly improved.

## accessibility 1.1.0

CRAN release: 2023-06-22

### New features

- The package now includes functions to estimate accessibility
  inequalities
  ([`palma_ratio()`](https://ipea.github.io/accessibility/dev/reference/palma_ratio.md)
  and
  [`gini_index()`](https://ipea.github.io/accessibility/dev/reference/gini_index.md))
  and poverty
  ([`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)).
- New accessibility functions
  [`spatial_availability()`](https://ipea.github.io/accessibility/dev/reference/spatial_availability.md)
  and
  [`balancing_cost()`](https://ipea.github.io/accessibility/dev/reference/balancing_cost.md).
- New vignette “Calculating accessibility inequality and poverty”.
- [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
  parameter `n` now accepts a numeric vector, instead of being
  restricted to a single number.
- [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md)
  parameters `cutoff` and `travel_cost` now accepts a numeric and a
  character vector, respectively, instead of being restricted to a
  single number/string.
- [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  parameter `interval` now accepts a list of numeric vectors, instead of
  being restricted to a single vector.
- The decay functions can now take numeric vectors as input, instead of
  being restricted to a single number (in the case of
  [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md),
  both `steps` and `weights` can take a `list` of `numeric` vectors as
  input, instead of being restricted to a single `numeric` vector each).

### Notes

- Various documentation tweaks.
- Added the new accessibility functions to the intro vignette.

## accessibility 1.0.1

CRAN release: 2022-10-06

### Bug fixes

- Fixed a bug in which
  [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
  would return `NA` values when filling missing ids (which should be
  filled with `Inf`, since they cannot reach any opportunities). This
  was also responsible for the warning reported in
  [\#27](https://github.com/ipea/accessibility/issues/27), which was
  also fixed.

## accessibility 1.0.0

CRAN release: 2022-07-22

The package has been through tremendous changes. Basically, there’s not
a single part of it that remained untouched: documentation, vignettes,
function names, parameter names, extra functionality, performance
improvements, etc. While it is impossible to highlight everything that
has been done, we’ll try to summarize some of the key points in the
following topics.

### Breaking changes

- Accessibility functions previously worked with a single input dataset:
  `data`. Now they require two input datasets: `travel_matrix` and
  `land_use_data`.
- Function names were changed:
  - `time_to_closest()` -\>
    [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
  - `cumulative_time_cutoff()` -\>
    [`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md)
  - `cumulative_time_interval()` -\>
    [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  - `gravity_access()` -\>
    [`gravity()`](https://ipea.github.io/accessibility/dev/reference/gravity.md)
- Parameter names were changed:
  - `opportunity_col` -\> `opportunity`
  - `travel_cost_col` -\> `travel_cost`
  - `by_col` -\> `active`
  - In
    [`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md):
    `n_opportunities` -\> `n`
  - In
    [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md):
    `stat` -\> `summary_function`
  - In
    [`floating_catchment_area()`](https://ipea.github.io/accessibility/dev/reference/floating_catchment_area.md):
    `population_col` -\> `demand`
  - In
    [`floating_catchment_area()`](https://ipea.github.io/accessibility/dev/reference/floating_catchment_area.md):
    `fca_metric` -\> `method`
- Parameter required values were changed:
  - `active` now takes a `logical`, instead of a string (which `by_col`
    previously took).
  - In
    [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md):
    `summary_function` now takes a `function`, instead of a string
    (which `stat` previously took).

### New features

- New function
  [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md).
- New parameter `interval_increment` to
  [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md),
  used to specify how many travel cost units separate the cutoffs used
  to calculate the accessibility estimates which will be used to
  calculate the summary estimate within the specified interval.
- All accessibility functions gained a `group_by` parameter, that allows
  accessibility estimates to be grouped by one or more columns present
  in `travel_matrix`.
- All accessibility functions (but
  [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md))
  gained a `fill_missing_ids` parameter, that includes in the results
  origins whose accessibility would be 0 but, due to some commonly
  overlooked implementation details, are usually left out from the
  output.
  [`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)
  doesn’t have this parameter because its result will always include all
  origins, otherwise the summary measure wouldn’t be calculated
  properly.

## accessibility 0.1.0

CRAN release: 2022-06-30

- Initial CRAN release.
