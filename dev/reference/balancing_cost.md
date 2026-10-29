# Balancing cost accessibility measure

Calculates the balancing cost measure, which is defined as the travel
cost required to reach as many opportunities as the number of people in
a given origin. Originally proposed by Barboza et al. (2021) , under the
name "balancing time".

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
balancing_cost(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  demand,
  cost_increment = 1,
  group_by = character(0),
  fill_missing_ids = TRUE
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

- cost_increment:

  A number. The cost increment that should be used when defining the
  travel cost distribution from which the potential balancing costs will
  be picked. For example, an increment of 1 tends to be suitable for
  travel time distributions, meaning that the function will first check
  if any origins reach their balancing cost with a travel time of 0
  minutes, then 1 minute, 2 minutes, 3, 4, ..., etc. An increment of 1
  might be too big for a distribution of monetary costs, on the other
  hand, which could possibly benefit from a smaller increment of 0.05,
  for example, resulting in the function looking for balancing costs
  first at a cost of 0, then 0.05, 0.10, ..., etc. Defaults to 1.

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

  A `logical`. Origins that never reach as many opportunities as there
  are people residing in them, as well as (when `group_by` is not empty)
  combinations of groups and origins missing from the travel matrix,
  would not be included in the output. When `TRUE` (the default), the
  function identifies which combinations would be left out and fills
  their respective balancing costs with `NA`, which incurs a performance
  penalty.

## Value

A data frame containing the balancing cost of each origin in the travel
matrix. Origins with a `NA` balancing cost never reach as many
opportunities as there are people residing in them, given the specified
travel matrix.

## References

Barboza MH, Carneiro MS, Falavigna C, Luz G, Orrico R (2021). “Balancing
Time: Using a New Accessibility Measure in Rio de Janeiro.” *Journal of
Transport Geography*, **90**, 102924. ISSN 09666923.
[doi:10.1016/j.jtrangeo.2020.102924](https://doi.org/10.1016/j.jtrangeo.2020.102924)
.

## See also

Other accessibility measures:
[`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md),
[`gravity()`](https://ipea.github.io/accessibility/dev/reference/gravity.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

bc <- balancing_cost(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population"
)
head(bc)
#>                 id travel_time
#>             <char>       <num>
#> 1: 89a881a5a2bffff          15
#> 2: 89a881a5a2fffff          13
#> 3: 89a881a5a67ffff          23
#> 4: 89a881a5a6bffff           7
#> 5: 89a881a5a6fffff          10
#> 6: 89a881a5b03ffff           6
```
