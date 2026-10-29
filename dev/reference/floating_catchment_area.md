# Floating catchment area accessibility

Calculates accessibility accounting for the competition of resources
using a measure from the floating catchment area (FCA) family. Please
see the details for the available FCA measures.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
floating_catchment_area(
  travel_matrix,
  land_use_data,
  opportunity,
  travel_cost,
  demand,
  method,
  decay_function,
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

- method:

  A string. Which floating catchment area measure to use. Current
  available options are `"2sfca"` and `"bfca"`. More info in the
  details.

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

A data frame containing the accessibility estimates for each origin in
the travel matrix.

## Details

The package currently includes two built-in FCA measures:

- 2SFCA - the 2-Step Floating Catchment Area measure was the first
  accessibility metric in the FCA family. It was originally proposed by
  Luo and Wang (2003) .

- BFCA - the Balanced Floating Catchment Area measure calculates
  accessibility accounting for competition effects while simultaneously
  correcting for issues of inflation of demand and service levels that
  are present in other FCA measures. It was originally proposed by Paez
  et al. (2019) and named in Pereira et al. (2021) .

## References

Luo W, Wang F (2003). “Measures of Spatial Accessibility to Health Care
in a GIS Environment: Synthesis and a Case Study in the Chicago Region.”
*Environment and Planning B: Planning and Design*, **30**(6), 865–884.
ISSN 0265-8135, 1472-3417.
[doi:10.1068/b29120](https://doi.org/10.1068/b29120) .  
  
Paez A, Higgins CD, Vivona SF (2019). “Demand and Level of Service
Inflation in Floating Catchment Area (FCA) Methods.” *PLOS ONE*,
**14**(6), e0218773. ISSN 1932-6203.
[doi:10.1371/journal.pone.0218773](https://doi.org/10.1371/journal.pone.0218773)
.  
  
Pereira RHM, Braga CKV, Servo LM, Serra B, Amaral P, Gouveia N, Paez A
(2021). “Geographic Access to COVID-19 Healthcare in Brazil Using a
Balanced Float Catchment Area Approach.” *Social Science & Medicine*,
**273**, 113773. ISSN 0277-9536.
[doi:10.1016/j.socscimed.2021.113773](https://doi.org/10.1016/j.socscimed.2021.113773)
.

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

# 2SFCA with a step decay function
df <- floating_catchment_area(
  travel_matrix,
  land_use_data,
  method = "2sfca",
  decay_function = decay_binary(cutoff = 50),
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population"
)
head(df)
#>                 id      jobs
#>             <char>     <num>
#> 1: 89a88cdb57bffff 0.4278111
#> 2: 89a88cdb597ffff 0.3863614
#> 3: 89a88cdb5b3ffff 0.4501725
#> 4: 89a88cdb5cfffff 0.5366707
#> 5: 89a88cd909bffff 0.4280401
#> 6: 89a88cd90b7ffff 0.5176583


# BFCA with an exponential decay function
df <- floating_catchment_area(
  travel_matrix,
  land_use_data,
  method = "bfca",
  decay_function = decay_exponential(decay_value = 0.5),
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population"
)
head(df)
#>                 id       jobs
#>             <char>      <num>
#> 1: 89a88cdb57bffff 0.10280082
#> 2: 89a88cdb597ffff 0.30930287
#> 3: 89a88cdb5b3ffff 0.07288551
#> 4: 89a88cdb5cfffff 0.09759117
#> 5: 89a88cd909bffff 0.07390234
#> 6: 89a88cd90b7ffff 1.22525579
```
