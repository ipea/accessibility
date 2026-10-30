# Cumulative access based on maximum travel time interval

Calculates the average or median number of opportunities that can be
reached considering multiple maximum travel cost thresholds within a
given travel cost interval specified by the user. The time interval
cumulative accessibility measure was originally proposed by Tomasiello
et al. (2023) .

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
cumulative_interval(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  interval,
  interval_increment = 1,
  summary_function = stats::median,
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

- interval:

  A `numeric` vector of length 2. Indicates the start and end points of
  the interval of travel cost thresholds to be used. The first entry
  must be lower than the second.

- interval_increment:

  A `numeric`. How many travel cost units separate the cutoffs used to
  calculate the accessibility estimates which will be used to calculate
  the summary estimate within the specified interval. Should be thought
  as the resolution of the distribution of travel costs within the
  interval. Defaults to 1.

- summary_function:

  A function. This function is used to summarize a distribution of
  accessibility estimates within a travel cost interval as a single
  value. Can be any function that takes an arbitrary number of numeric
  values as input and returns a single number as output. Defaults to
  [`stats::median()`](https://rdrr.io/r/stats/median.html).

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

  A `logical`. Origins (or destinations, when `active` is `FALSE`) that
  cannot reach any opportunity within the interval would not be included
  in the output. When `TRUE` (the default), the function includes them
  with an accessibility of 0.

## Value

A data frame containing the accessibility estimates for each
origin/destination (depending if `active` is `TRUE` or `FALSE`) in the
travel matrix.

## References

Tomasiello DB, Herszenhut D, Oliveira JLA, Braga CKV, Pereira RHM
(2023). “A Time Interval Metric for Cumulative Opportunity
Accessibility.” *Applied Geography*, **157**, 103007. ISSN 0143-6228.
[doi:10.1016/j.apgeog.2023.103007](https://doi.org/10.1016/j.apgeog.2023.103007)
.

## See also

Other cumulative access:
[`cumulative_cutoff()`](https://ipea.github.io/accessibility/reference/cumulative_cutoff.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

df <- cumulative_interval(
  travel_matrix = travel_matrix,
  land_use_data = land_use_data,
  interval = c(20, 30),
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df)
#>                 id schools
#>             <char>   <num>
#> 1: 89a881a5a2bffff       0
#> 2: 89a881a5a2fffff       3
#> 3: 89a881a5a67ffff       0
#> 4: 89a881a5a6bffff       0
#> 5: 89a881a5a6fffff       0
#> 6: 89a881a5b03ffff      11

df <- cumulative_interval(
  travel_matrix = travel_matrix,
  land_use_data = land_use_data,
  interval = c(40, 80),
  opportunity = "jobs",
  travel_cost = "travel_time"
)
head(df)
#>                 id   jobs
#>             <char>  <num>
#> 1: 89a881a5a2bffff 371990
#> 2: 89a881a5a2fffff 395808
#> 3: 89a881a5a67ffff 378286
#> 4: 89a881a5a6bffff 355500
#> 5: 89a881a5a6fffff 347725
#> 6: 89a881a5b03ffff 414109
```
