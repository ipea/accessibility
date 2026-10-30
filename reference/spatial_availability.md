# Spatial availability

Calculates spatial availability, an accessibility measure proposed by
Soukhov et al. (2023) that takes into account competition effects. The
accessibility levels that result from using this measure are
proportional both to the demand in each origin and to the travel cost it
takes to reach the destinations. The spatial availability is a
particular case of `constrained_accessibility(constraint = "singly")`.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
spatial_availability(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  demand,
  decay_function,
  alpha = 1,
  group_by = character(0),
  fill_missing_ids = TRUE,
  detailed_results = FALSE
)
```

## Arguments

- travel_matrix:

  A data frame. The travel matrix describing the costs (i.e. travel
  time, distance, monetary cost, etc.) between the origins and
  destinations in the study area. Must contain the columns `from_id`,
  `to_id` and any others specified in `travel_cost`.

- land_use_data:

  A data frame. The distribution of opportunities within the study area
  cells. Must contain the columns `id` and any others specified in
  `opportunity`. `NA` values, and ids in `travel_matrix` that are
  missing from this table, are treated as 0.

- opportunity:

  A string. The name of the column in `land_use_data` with the number of
  opportunities/resources/services to be considered when calculating
  accessibility levels.

- travel_cost:

  A string. The name of the column in `travel_matrix` with the travel
  cost between origins and destinations. The notion of cost here is
  generic over any kind of numeric travel cost, such as distance, time
  and money.

- demand:

  A string. The name of the column in `land_use_data` with the number of
  opportunity-demanders at each origin (e.g., people) that will be
  considered.

- decay_function:

  A `function` that converts travel cost into an impedance factor used
  to weight opportunities. This function should take a `numeric` vector
  and also return a `numeric` vector as output, with the same length as
  the input. For convenience, the package currently includes the
  following functions:
  [`decay_binary()`](https://ipea.github.io/accessibility/reference/decay_binary.md),
  [`decay_exponential()`](https://ipea.github.io/accessibility/reference/decay_exponential.md),
  [`decay_linear()`](https://ipea.github.io/accessibility/reference/decay_linear.md),
  [`decay_logistic()`](https://ipea.github.io/accessibility/reference/decay_logistic.md),
  [`decay_power()`](https://ipea.github.io/accessibility/reference/decay_power.md)
  and
  [`decay_stepped()`](https://ipea.github.io/accessibility/reference/decay_stepped.md).
  See the documentation of each decay function for more details.

- alpha:

  A `numeric`. A parameter used to modulate the effect of demand by
  population. When less than 1, opportunities are allocated more rapidly
  to smaller centers relative to larger ones; values higher than 1
  achieve the opposite effect.

- group_by:

  A `character` vector. When not `character(0)` (the default), indicates
  the `travel_matrix` columns that should be used to group the
  accessibility estimates by. For example, if `travel_matrix` includes a
  departure time column, that specifies the departure time of each entry
  in the data frame, passing `"departure_time"` to this parameter
  results in accessibility estimates grouped by origin and by departure
  time.

  Accessibility is calculated separately for each unique combination of
  grouping variables. For constrained accessibility measures, each group
  is treated as an independent land-use-transportation system.

- fill_missing_ids:

  A `logical`. When calculating grouped accessibility estimates (i.e.
  when `group_by` is not empty), some combinations of groups and origins
  may be missing. For example, if a single trip can depart from origin
  `A` at 7:15am and reach destination `B` within 55 minutes, but no
  trips departing from `A` at 7:30am can be completed at all, this
  second combination will not be included in the output. When `TRUE`
  (the default), the function identifies which combinations would be
  left out and fills their respective accessibility values with 0, which
  incurs a performance penalty.

- detailed_results:

  A `logical`. Whether to return spatial availability results aggregated
  by origin-destination pair (`TRUE`) or by origin (`FALSE`, the
  default). When `TRUE`, the output also includes the demand, impedance
  and combined balancing factors used to calculate spatial availability.
  Please note that the argument `fill_missing_ids` does not affect the
  output when `detailed_results` is `TRUE`.

## Value

A data frame containing the spatial availability estimates for each
origin in the travel matrix. When `detailed_results` is `TRUE`, the
estimates are given for each origin-destination pair instead, alongside
the balancing factors used to calculate them.

## References

Soukhov A, Páez A, Higgins CD, Mohamed M (2023). “Introducing Spatial
Availability, a Singly-Constrained Measure of Competitive
Accessibility.” *PLOS ONE*, **18**(1), e0278468. ISSN 1932-6203.
[doi:10.1371/journal.pone.0278468](https://doi.org/10.1371/journal.pone.0278468)
.

## See also

Other Constrained accessibility:
[`constrained_accessibility()`](https://ipea.github.io/accessibility/reference/constrained_accessibility.md)

## Examples

``` r
# the example below is based on Soukhov et al. (2023) paper

travel_matrix <- data.table::data.table(
  from_id = rep(c("A", "B", "C"), each = 3),
  to_id = as.character(rep(1:3, 3)),
  travel_time = c(15, 30, 100, 30, 15, 100, 100, 100, 15)
)
land_use_data <- data.table::data.table(
  id = c("A", "B", "C", "1", "2", "3"),
  population = c(50000, 150000, 10000, 0, 0, 0),
  jobs = c(0, 0, 0, 100000, 100000, 10000)
)

df <- spatial_availability(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population",
  decay_function = decay_exponential(decay_value = 0.1)
)
df
#>        id       jobs
#>    <char>      <num>
#> 1:      A  66833.466
#> 2:      B 133203.363
#> 3:      C   9963.171

detailed_df <- spatial_availability(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population",
  decay_function = decay_exponential(decay_value = 0.1),
  detailed_results = TRUE
)
detailed_df
#>    from_id  to_id demand_bal_fac impedance_bal_fac combined_bal_fac
#>     <char> <char>          <num>             <num>            <num>
#> 1:       A      1     0.23809524      0.8174384949     5.990064e-01
#> 2:       A      2     0.23809524      0.1823951823     6.922691e-02
#> 3:       A      3     0.23809524      0.0002033856     1.013219e-03
#> 4:       B      1     0.71428571      0.1823951823     4.009692e-01
#> 5:       B      2     0.71428571      0.8174384949     9.307605e-01
#> 6:       B      3     0.71428571      0.0002033856     3.039656e-03
#> 7:       C      1     0.04761905      0.0001663229     2.437577e-05
#> 8:       C      2     0.04761905      0.0001663229     1.262535e-05
#> 9:       C      3     0.04761905      0.9995932288     9.959471e-01
#>            jobs
#>           <num>
#> 1: 59900.642536
#> 2:  6922.691048
#> 3:    10.132187
#> 4: 40096.919886
#> 5: 93076.046417
#> 6:    30.396561
#> 7:     2.437577
#> 8:     1.262535
#> 9:  9959.471253
```
