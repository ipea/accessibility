# Minimum travel cost to closest N number of opportunities

Calculates the minimum travel cost to the closest N number of
opportunities.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
cost_to_closest(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  n = 1,
  group_by = character(0),
  active = TRUE,
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

- n:

  A `numeric` vector. The minimum number of opportunities that should be
  considered. Defaults to 1. If more than one value is provided, the
  output includes an extra column specifying the number of opportunities
  that the minimum travel cost refers to.

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

- active:

  A logical. When `TRUE`, the function calculates active accessibility
  (the quantity of opportunities that can be reached from a given
  origin). When `FALSE`, it calculates passive accessibility (by how
  many people each destination can be reached), which is equivalent to
  the notion of market potential.

- fill_missing_ids:

  A `logical`. Calculating minimum travel cost to closest N number of
  opportunities may result in missing ids in the output if they cannot
  reach the specified amount of opportunities across all destinations
  they can reach. For example, estimating the minimum travel time that
  an origin that can only reach 4 opportunities takes to reach 5
  opportunities results in such origin not being included in the output.
  When `TRUE` (the default), the function identifies which ids would be
  left out from the output and fills their respective minimum travel
  costs with `Inf`, which incurs a performance penalty.

## Value

A data frame containing the accessibility estimates for each
origin/destination (depending if `active` is `TRUE` or `FALSE`) in the
travel matrix.

## See also

Other accessibility measures:
[`balancing_cost()`](https://ipea.github.io/accessibility/dev/reference/balancing_cost.md),
[`gravity()`](https://ipea.github.io/accessibility/dev/reference/gravity.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

df <- cost_to_closest(
  travel_matrix,
  land_use_data,
  n = 1,
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df)
#>                 id travel_time
#>             <char>       <num>
#> 1: 89a881a5a2bffff          29
#> 2: 89a881a5a2fffff          24
#> 3: 89a881a5a67ffff          28
#> 4: 89a881a5a6bffff          33
#> 5: 89a881a5a6fffff          32
#> 6: 89a881a5b03ffff          17

df <- cost_to_closest(
  travel_matrix,
  land_use_data,
  n = c(1, 2),
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df)
#>                 id     n travel_time
#>             <char> <num>       <num>
#> 1: 89a881a5a2bffff     1          29
#> 2: 89a881a5a2bffff     2          32
#> 3: 89a881a5a2fffff     1          24
#> 4: 89a881a5a2fffff     2          25
#> 5: 89a881a5a67ffff     1          28
#> 6: 89a881a5a67ffff     2          31
```
