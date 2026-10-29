# Gravity-based accessibility measures

Calculates gravity-based accessibility using a decay function specified
by the user.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
gravity(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  decay_function,
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

- decay_function:

  A `function` that converts travel cost into an impedance factor used
  to weight opportunities. This function should take a `numeric` vector
  and also return a `numeric` vector as output, with the same length as
  the input. For convenience, the package currently includes the
  following functions:
  [`decay_binary()`](https://ipea.github.io/accessibility/dev/reference/decay_binary.md),
  [`decay_exponential()`](https://ipea.github.io/accessibility/dev/reference/decay_exponential.md),
  [`decay_linear()`](https://ipea.github.io/accessibility/dev/reference/decay_linear.md),
  [`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md),
  [`decay_power()`](https://ipea.github.io/accessibility/dev/reference/decay_power.md)
  and
  [`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md).
  See the documentation of each decay function for more details.

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

  A `logical`. When calculating grouped accessibility estimates (i.e.
  when `group_by` is not empty), some combinations of groups and origins
  may be missing. For example, if a single trip can depart from origin
  `A` at 7:15am and reach destination `B` within 55 minutes, but no
  trips departing from `A` at 7:30am can be completed at all, this
  second combination will not be included in the output. When `TRUE`
  (the default), the function identifies which combinations would be
  left out and fills their respective accessibility values with 0, which
  incurs a performance penalty.

## Value

A data frame containing the accessibility estimates for each
origin/destination (depending if `active` is `TRUE` or `FALSE`) in the
travel matrix.

## See also

Other accessibility measures:
[`balancing_cost()`](https://ipea.github.io/accessibility/dev/reference/balancing_cost.md),
[`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

df_linear <- gravity(
  travel_matrix,
  land_use_data,
  decay_function = decay_linear(cutoff = 50),
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df_linear)
#>                 id schools
#>             <char>   <num>
#> 1: 89a88cdb57bffff   9.260
#> 2: 89a88cdb597ffff  18.748
#> 3: 89a88cdb5b3ffff  20.900
#> 4: 89a88cdb5cfffff  13.660
#> 5: 89a88cd909bffff  18.980
#> 6: 89a88cd90b7ffff  24.780

df_exp <- gravity(
  travel_matrix,
  land_use_data,
  decay_function = decay_exponential(decay_value = 0.5),
  opportunity = "schools",
  travel_cost = "travel_time"
)
head(df_exp)
#>                 id      schools
#>             <char>        <num>
#> 1: 89a88cdb57bffff 2.705781e-06
#> 2: 89a88cdb597ffff 1.249277e-01
#> 3: 89a88cdb5b3ffff 8.269861e-03
#> 4: 89a88cdb5cfffff 3.023943e-03
#> 5: 89a88cd909bffff 3.059679e-02
#> 6: 89a88cd90b7ffff 8.581966e-02
```
