# Cumulative access based on a travel cost cutoff

Calculates the number of opportunities accessible under a given
specified travel cost cutoff.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
cumulative_cutoff(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  cutoff,
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

  A `character` vector. The name of the columns in `travel_matrix` with
  the travel costs between origins and destinations to be considered in
  the calculation.

- cutoff:

  Either a `numeric` vector or a list of `numeric` vectors, one for each
  cost specified in `travel_cost`. The travel cost cutoffs to consider
  when calculating accessibility levels. If a list, the function finds
  every single possible cutoff combination and uses them to calculate
  accessibility (e.g. if one specifies that travel time cutoffs should
  be 30 and 60 minutes and that monetary cost cutoffs should be 5 and 10
  dollars, the output includes accessibility estimates limited at 30 min
  & 5 dollars, 30 min & 10 dollars, 60 min & 5 dollars and 60 min & 10
  dollars). In these cases, cost constraints are considered
  simultaneously - i.e. only trips that take 30 minutes or less AND 5
  dollars or less to be completed, for example, are included in the
  accessibility output. The cutoff parameter is not included in the
  final output if the input includes only a single cutoff for a single
  travel cost.

- group_by:

  A `character` vector. When not `character(0)` (the default), indicates
  the `travel_matrix` columns that should be used to group the
  accessibility estimates by. For example, if `travel_matrix` includes a
  departure time column, that specifies the departure time of each entry
  in the data frame, passing `"departure_time"` to this parameter
  results in accessibility estimates grouped by origin and by departure
  time.

- active:

  A logical. When `TRUE`, the function calculates active accessibility
  (the quantity of opportunities that can be reached from a given
  origin). When `FALSE`, it calculates passive accessibility (by how
  many people each destination can be reached), which is equivalent to
  the notion of market potential.

- fill_missing_ids:

  A `logical`. Calculating cumulative accessibility may result in
  missing ids if they cannot reach any of the destinations within the
  specified travel cost cutoff. For example, using a travel time cutoff
  of 20 minutes, when estimating the accessibility of origin `A` that
  can only reach destinations with more than 40 minutes results in id
  `A` not being included in the output. When `TRUE` (the default), the
  function identifies which origins would be left out and fills their
  respective accessibility values with 0, which incurs a performance
  penalty.

## Value

A data frame containing the accessibility estimates for each
origin/destination (depending if `active` is `TRUE` or `FALSE`) in the
travel matrix.

## See also

Other cumulative access:
[`cumulative_interval()`](https://ipea.github.io/accessibility/dev/reference/cumulative_interval.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

# active accessibility: number of schools accessible from each origin
df <- cumulative_cutoff(
  travel_matrix = travel_matrix,
  land_use_data = land_use_data,
  cutoff = 30,
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df)
#>                 id schools
#>             <char>   <int>
#> 1: 89a881a5a2bffff       1
#> 2: 89a881a5a2fffff      10
#> 3: 89a881a5a67ffff       1
#> 4: 89a881a5a6bffff       0
#> 5: 89a881a5a6fffff       0
#> 6: 89a881a5b03ffff      14

df <- cumulative_cutoff(
  travel_matrix = travel_matrix,
  land_use_data = land_use_data,
  cutoff = c(30, 60),
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df)
#>                 id travel_time schools
#>             <char>       <num>   <int>
#> 1: 89a881a5a2bffff          30       1
#> 2: 89a881a5a2bffff          60      76
#> 3: 89a881a5a2fffff          30      10
#> 4: 89a881a5a2fffff          60      91
#> 5: 89a881a5a67ffff          30       1
#> 6: 89a881a5a67ffff          60      82

# passive accessibility: number of people that can reach each destination
df <- cumulative_cutoff(
  travel_matrix = travel_matrix,
  land_use_data = land_use_data,
  cutoff = 30,
  opportunity = "population",
  travel_cost = "travel_time",
  active = FALSE
)
head(df)
#>                 id population
#>             <char>      <int>
#> 1: 89a881a5a2bffff      11053
#> 2: 89a881a5a2fffff      31903
#> 3: 89a881a5a67ffff      12488
#> 4: 89a881a5a6bffff      14474
#> 5: 89a881a5a6fffff      15053
#> 6: 89a881a5b03ffff      69582

# using multiple travel costs
pareto_frontier <- readRDS(file.path(data_dir, "pareto_frontier.rds"))

df <- cumulative_cutoff(
  pareto_frontier,
  land_use_data = land_use_data,
  opportunity = "jobs",
  travel_cost = c("travel_time", "monetary_cost"),
  cutoff = list(c(20, 30), c(0, 5, 10))
)
head(df)
#>                 id travel_time monetary_cost  jobs
#>             <char>       <num>         <num> <int>
#> 1: 89a881a5a2bffff          20             0   397
#> 2: 89a881a5a2bffff          20             5   397
#> 3: 89a881a5a2bffff          20            10   397
#> 4: 89a881a5a2bffff          30             0   846
#> 5: 89a881a5a2bffff          30             5 20923
#> 6: 89a881a5a2bffff          30            10 20923
```
