# Constrained accessibility

Calculates accessibility using constraints, as proposed in Soukhov et
al. (2025) . Accessibility is conceptualised as potential spatial
interaction. This function covers three constraint cases. Please see the
Details section for more information.

## Usage

``` r
constrained_accessibility(
  travel_matrix,
  land_use_data,
  travel_cost,
  demand = NULL,
  supply = NULL,
  constraint,
  decay_function,
  active = NULL,
  error_threshold = 0.001,
  improvement_threshold = 1e-06,
  max_iterations = 1000,
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

- travel_cost:

  A string. The name of the column in `travel_matrix` with the travel
  cost between origins and destinations. The notion of cost here is
  generic over any kind of numeric travel cost, such as distance, time
  and money.

- demand:

  A string. The name of the column in `land_use_data` with the number of
  opportunity-demanders at each origin (e.g., people) that will be
  considered.

- supply:

  A string. The name of the column in `land_use_data` with the number of
  opportunity supply at each destination (e.g., jobs, school-seats) that
  will be considered.

- constraint:

  A string. One of `"total"`, `"singly"`, or `"doubly"`. See Details
  section for more information.

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

- active:

  A logical. When `TRUE`, the function calculates active accessibility
  (the quantity of opportunities that can be reached from a given
  origin). When `FALSE`, it calculates passive accessibility (by how
  many people each destination can be reached), which is equivalent to
  the notion of market potential. This parameter only works for
  `constraint` types `"total"` and `"singly"`. Ignored for
  `constraint = "doubly"`.

- error_threshold:

  Numeric. Convergence criterion used only for calibration in the
  doubly-constrained case (`constraint = "doubly"`).

- improvement_threshold:

  Numeric. Convergence criterion for improvement used only for
  calibration in the doubly-constrained case (`constraint = "doubly"`).

- max_iterations:

  Integer. Maximum iterations used only for calibration in the
  doubly-constrained case (`constraint = "doubly"`).

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

  Logical. Whether to return detailed OD-level results for
  `constraint = "total"`- and `constraint = "singly"` accessibility.
  Currently ignored for `constraint = "doubly"` accessibility, which
  always returns OD-level flows.

## Value

A data frame of the same class as `travel_matrix` (`data.table`,
`data.frame` or `tibble`). Its columns depend on `constraint`, `active`
and `detailed_results`:

- `constraint = "total"` or `"singly"`, `detailed_results = FALSE`: one
  row per origin (`from_id`, when `active = TRUE`) or destination
  (`to_id`, when `active = FALSE`), plus the `group_by` columns.
  Accessibility is in a column named `supply` (active) or `demand`
  (passive).

- `constraint = "total"`, `detailed_results = TRUE`: one row per
  origin-destination pair, with the columns `from_id`, `to_id`, the
  weighted opportunities (`weighted_supply` or `weighted_demand`), the
  share of the regional total allocated to the pair (`kappa_total` or
  `hatkappa_total`), the allocated flow (`supply` or `demand`) and the
  scaling constant (`K_total` or `hatK_total`).

- `constraint = "singly"`, `detailed_results = TRUE`: one row per
  origin-destination pair, with the columns `from_id`, `to_id`, the
  allocation share (`kappa_singly` or `hatkappa_singly`), the allocated
  flow (`supply` or `demand`) and the balancing factor (`B_j` or `A_i`).

- `constraint = "doubly"`: one row per origin-destination pair, with the
  columns `from_id`, `to_id`, `flow`, the balancing factors `A_i` and
  `B_j`, `kappa_doubly` and the final balancing `error`.
  `detailed_results` and `active` are not read.

Detailed results include the `group_by` columns and, when the decay
function has several values, `decay_function_arg`.

## Details

This function covers the family of constrained accessibility measures
proposed in Soukhov et al. (2025) .

For these measures, each group or decay value is treated as an
independent land-use-transportation system. This is not a multimodal
model that splits demand or supply across groups. Instead, each group is
calculated as if the function were run separately on that group's rows
of `travel_matrix`. The total allocated within a group is the sum of the
opportunities (or population) associated with the ids that appear in
that group's rows.

As well, when `fill_missing_ids = TRUE`, ids that are absent from a
particular group's rows are still returned with accessibility equal to
0. This doesn't apply to `constraint = "doubly"`, which ignores
`fill_missing_ids` and returns every origin-destination pair of the ids
in each group.

### Total Constrained Accessibility

Allocates the system-wide total proportionally based on travel impedance
between origins and destinations. This measure uses the logic of a total
(or 'unconstrained' by Wilson's terms) constraint.

Use this measure when the total quantity of **supply** OR **demand** in
the system is known and representing accessibility as a proportion of
this total is meaningful.

#### Requirement:

- `supply` must be provided when `active = TRUE`, and `demand` when
  `active = FALSE`. The other argument is ignored, so the same call can
  be used with `constraint = "singly"`, which requires both.

#### Interpretation:

- `active = TRUE` (*active accessibility*): Results represent the total
  number of **opportunities** (supply) accessible from each origin based
  on region-relative travel impedance. The units are in 'supply' (e.g.,
  jobs, school seats).

  - If `detailed_results = FALSE`, outputs are aggregated and returned
    by origin.

  - If `detailed_results = TRUE`, OD-level flows are returned. Summing
    flows by origin equals the aggregated result.

- `active = FALSE` (*passive accessibility*, the notion of market
  potential): Results represent the total number of **population**
  (demand) that can reach each destination based on region-relative
  travel impedance. The units are in 'demand' (e.g., population).

  - If `detailed_results = FALSE`, outputs are aggregated by
    destination.

  - If `detailed_results = TRUE`, OD-level flows are returned. Summing
    flows by destination equals the aggregated result.

#### Use cases:

- Active accessibility (aggregated): "How many jobs can be reached from
  origin zone A given its region-relative travel impedance?"

- Active accessibility (flow-level): "How many jobs can be reached by
  flow A-\>1 given A-\>1's region-relative travel impedance?"

- Passive accessibility (aggregated): "How many people can reach
  destination zone 1 given its region-relative travel impedance?"

- Passive accessibility (flow-level): "How many people are reached by
  flow 1-\>A given 1-\>A's region-relative travel impedance?"

### Singly Constrained Accessibility

Allocates opportunities at each destination (or population at each
origin) proportionally based on travel impedance and the opposite
marginal. This measure uses the logic of single constraint from Wilson
(1971) .

Use this measure when modeling **competition**, where both demand and
supply are conceptualised to influence accessibility but only one side
is fixed. The measure distributes flows so that totals match the
constrained side while weighting by travel impedance and the
unconstrained side.

#### Requirements:

- Both `demand` and `supply` must be provided (the logical for `active`
  determines if either demand or supply is constrained).

#### Interpretation:

- `active = TRUE` (*active accessibility*): constrains supply. Results
  represent the total number of **opportunities** (supply) accessible
  from each origin based on region-relative travel impedance and
  population at the origin. The units are in 'supply' (e.g., jobs,
  school seats).

  - If `detailed_results = FALSE`, outputs are aggregated and returned
    by origin.

  - If `detailed_results = TRUE`, OD-level flows are returned. Summing
    flows by origin equals the aggregated result.

- `active = FALSE` (*passive accessibility*, the notion of market
  potential): constrains demand. Results represent the total number of
  **population** (demand) that can reach each destination based on
  region-relative travel impedance and opportunities at the destination.
  The units are in 'demand' (e.g., population).

  - If `detailed_results = FALSE`, outputs are aggregated by
    destination.

  - If `detailed_results = TRUE`, OD-level flows are returned. Summing
    flows by destination equals the aggregated result.

#### Use cases:

- Active accessibility (aggregated): "How many jobs can be reached from
  origin zone A given its region-relative travel impedance and demand?"

- Active accessibility (flow-level): "How many jobs can be reached by
  flow A-\>1 given A-\>1's region-relative travel impedance and demand?"

- Passive accessibility (aggregated): "How many people can reach
  destination zone 1 given its region-relative travel impedance and
  supply?"

- Passive accessibility (flow-level): "How many people are reached by
  flow 1-\>A given 1-\>A's region-relative travel impedance and supply?"

**NOTE:** the active form of this measure yields equivalent results to
the
[`spatial_availability()`](https://ipea.github.io/accessibility/reference/spatial_availability.md)
function, through different logic.

### Doubly Constrained Accessibility

Allocates flows so supply at each destination matches demand at each
origin. It uses Wilson's *doubly-constrained* gravity model Wilson
(1971) .

The model uses iterative proportional fitting to update balancing
factors in order to calibrate OD flows on both margins (`A_i` for
origins and `B_j` for destinations) until convergence (i.e. the sum of
`demand` and `supply` match). This guarantees that flows satisfy both
marginals while being weighted by travel impedance.

#### Requirements:

- Both `demand` and `supply` must be provided.

- Unlike `total` and `singly`, `doubly` requires the sum of demand and
  supply to match; otherwise, an error is raised. When `group_by` or
  multiple decay values are used, the totals must match within each
  independently balanced system.

- `active` is ignored. Since supply must match demand, their units are
  the same and there is no distinction between 'active' and 'passive'
  notions.

- `detailed_results` is currently ignored for doubly-constrained
  accessibility. OD-level flows are always returned.

#### Interpretation:

- Results include OD-level flows (`flow`) along with balancing factors
  (`A_i`, `B_j`) and travel impedance weights. The resulting flows
  represent the distribution of demand and supply across all
  origin-destination pairs. NOTE: OD flows are in flow units (jointly
  determined by demand and supply).

#### Use cases:

- flow-level: "What is the count of A-\>1 flows given A-\>1's
  region-relative travel impedance, demand and supply?"

## References

Soukhov A, Pereira RHM, Higgins CD, Páez A (2025). “A family of
accessibility measures derived from spatial interaction principles.”
*PLoS One*, **20**(11), e0335951.
[doi:10.1371/journal.pone.0335951](https://doi.org/10.1371/journal.pone.0335951)
.  
  
Wilson AG (1971). “A family of spatial interaction models, and
associated developments.” *Environment and Planning A*, **3**(1), 1–32.
[doi:10.1068/a030001](https://doi.org/10.1068/a030001) .

## See also

Other Constrained accessibility:
[`spatial_availability()`](https://ipea.github.io/accessibility/reference/spatial_availability.md)

## Examples

``` r
# Load demo data shipped with the package
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

# Total-constrained (active accessibility, aggregated): returns units of
# accessible supply by origin (requires supply)
constrained_accessibility(
  travel_matrix   = travel_matrix,
  land_use_data   = land_use_data,
  travel_cost     = "travel_time",
  constraint      = "total",
  decay_function  = decay_exponential(0.1),
  demand          = NULL,
  supply          = "jobs",
  active          = TRUE,
  detailed_results = FALSE
)
#>              from_id   supply
#>               <char>    <num>
#>   1: 89a88cdb57bffff 263.8175
#>   2: 89a88cdb597ffff 264.7306
#>   3: 89a88cdb5b3ffff 319.5332
#>   4: 89a88cdb5cfffff 428.2523
#>   5: 89a88cd909bffff 291.7166
#>  ---                         
#> 894: 89a881acda3ffff 280.1091
#> 895: 89a88cdb543ffff 697.2299
#> 896: 89a88cda667ffff 346.8143
#> 897: 89a88cd900fffff 113.1569
#> 898: 89a881aebafffff   0.0000

# Total-constrained (passive accessibility, aggregated): returns units of
# accessible demand by destination  (requires demand)
constrained_accessibility(
  travel_matrix  = travel_matrix,
  land_use_data  = land_use_data,
  travel_cost    = "travel_time",
  constraint     = "total",
  decay_function = decay_exponential(0.1),
  demand         = "population",
  supply         = NULL,
  active         = FALSE,
  detailed_results = FALSE
)
#>                to_id       demand
#>               <char>        <num>
#>   1: 89a88cdb57bffff  720.1584302
#>   2: 89a88cdb597ffff  958.7228358
#>   3: 89a88cdb5b3ffff 1074.8576863
#>   4: 89a88cdb5cfffff  632.9250575
#>   5: 89a88cd909bffff  882.5883640
#>  ---                             
#> 894: 89a881ae92fffff   13.4118931
#> 895: 89a881ae923ffff    0.2403741
#> 896: 89a881ae9afffff    3.6023628
#> 897: 89a88cd8407ffff   27.6942661
#> 898: 89a881aebafffff    0.0000000

# Singly-constrained (active accessibility, aggregated): returns units of
# accessible supply by origin (requires supply and demand)
constrained_accessibility(
  travel_matrix   = travel_matrix,
  land_use_data   = land_use_data,
  travel_cost     = "travel_time",
  constraint      = "singly",
  decay_function  = decay_exponential(0.1),
  demand          = "population",
  supply          = "jobs",
  active          = TRUE,
  detailed_results = FALSE
)
#>              from_id    supply
#>               <char>     <num>
#>   1: 89a88cdb57bffff  186.0876
#>   2: 89a88cdb597ffff  140.0738
#>   3: 89a88cdb5b3ffff  736.5830
#>   4: 89a88cdb5cfffff  900.9284
#>   5: 89a88cd909bffff    0.0000
#>  ---                          
#> 894: 89a881acda3ffff  453.8818
#> 895: 89a88cdb543ffff 1184.0239
#> 896: 89a88cda667ffff  276.2530
#> 897: 89a88cd900fffff  103.5370
#> 898: 89a881aebafffff    0.0000

# Doubly-constrained: returns units of flow (requires both demand and supply
# with matching totals)

# Using a small toy dataset with matching totals.
tm_small <- data.table::data.table(
  expand.grid(from_id = c("1","2","3"), to_id = c("1","2","3"))
)
tm_small[, travel_time := c(10, 30, 15, 30, 10, 25, 15, 25, 10)]
#>    from_id  to_id travel_time
#>     <fctr> <fctr>       <num>
#> 1:       1      1          10
#> 2:       2      1          30
#> 3:       3      1          15
#> 4:       1      2          30
#> 5:       2      2          10
#> 6:       3      2          25
#> 7:       1      3          15
#> 8:       2      3          25
#> 9:       3      3          10
lu_small <- data.table::data.table(
  id         = c("1","2","3"),
  population = c(4, 10, 6),   # sum = 20
  jobs       = c(7,  5,  8)   # sum = 20
)

constrained_accessibility(
  travel_matrix   = tm_small,
  land_use_data   = lu_small,
  travel_cost     = "travel_time",
  constraint      = "doubly",
  decay_function  = decay_exponential(0.1),
  demand          = "population",
  supply          = "jobs"
)
#>    from_id  to_id       flow       A_i      B_j kappa_doubly        error
#>     <fctr> <fctr>      <num>     <num>    <num>        <num>        <num>
#> 1:       1      1 2.52693731 0.1721781 1.424797   0.36099104 0.0007282429
#> 2:       1      2 0.09995405 0.1721781 0.583010   0.01999081 0.0007282429
#> 3:       1      3 1.37651660 0.1721781 1.119684   0.17206457 0.0007282429
#> 4:       2      1 2.15341665 0.4336710 1.424797   0.30763095 0.0007282429
#> 5:       2      2 4.65063122 0.4336710 0.583010   0.93012624 0.0007282429
#> 6:       2      3 3.18866970 0.4336710 1.119684   0.39858371 0.0007282429
#> 7:       3      1 2.31964604 0.1737245 1.424797   0.33137801 0.0007282429
#> 8:       3      2 0.24941474 0.1737245 0.583010   0.04988295 0.0007282429
#> 9:       3      3 3.43481370 0.1737245 1.119684   0.42935171 0.0007282429

# With several decay values, each one is balanced separately
constrained_accessibility(
  travel_matrix   = tm_small,
  land_use_data   = lu_small,
  travel_cost     = "travel_time",
  constraint      = "doubly",
  decay_function  = decay_exponential(c(0.1, 0.5)),
  demand          = "population",
  supply          = "jobs"
)
#>     from_id  to_id decay_function_arg         flow          A_i        B_j
#>      <fctr> <fctr>              <num>        <num>        <num>      <num>
#>  1:       1      1                0.1 2.526937e+00    0.1721781  1.4247972
#>  2:       1      2                0.1 9.995405e-02    0.1721781  0.5830100
#>  3:       1      3                0.1 1.376517e+00    0.1721781  1.1196837
#>  4:       2      1                0.1 2.153417e+00    0.4336710  1.4247972
#>  5:       2      2                0.1 4.650631e+00    0.4336710  0.5830100
#>  6:       2      3                0.1 3.188670e+00    0.4336710  1.1196837
#>  7:       3      1                0.1 2.319646e+00    0.1737245  1.4247972
#>  8:       3      2                0.1 2.494147e-01    0.1737245  0.5830100
#>  9:       3      3                0.1 3.434814e+00    0.1737245  1.1196837
#> 10:       1      1                0.5 3.938944e+00    0.6091640 34.2736199
#> 11:       1      2                0.5 2.920245e-08    0.6091640  0.0078356
#> 12:       1      3                0.5 6.876651e-02    0.6091640  6.3782471
#> 13:       2      1                0.5 1.390083e+00 1894.0873923 34.2736199
#> 14:       2      2                0.5 4.999998e+00 1894.0873923  0.0078356
#> 15:       2      3                0.5 3.601723e+00 1894.0873923  6.3782471
#> 16:       3      1                0.5 1.670972e+00    2.0987882 34.2736199
#> 17:       3      2                0.5 1.838574e-06    2.0987882  0.0078356
#> 18:       3      3                0.5 4.329510e+00    2.0987882  6.3782471
#>     kappa_doubly        error
#>            <num>        <num>
#>  1: 3.609910e-01 0.0007282429
#>  2: 1.999081e-02 0.0007282429
#>  3: 1.720646e-01 0.0007282429
#>  4: 3.076310e-01 0.0007282429
#>  5: 9.301262e-01 0.0007282429
#>  6: 3.985837e-01 0.0007282429
#>  7: 3.313780e-01 0.0007282429
#>  8: 4.988295e-02 0.0007282429
#>  9: 4.293517e-01 0.0007282429
#> 10: 5.627063e-01 0.0008195559
#> 11: 5.840490e-09 0.0008195559
#> 12: 8.595813e-03 0.0008195559
#> 13: 1.985833e-01 0.0008195559
#> 14: 9.999996e-01 0.0008195559
#> 15: 4.502154e-01 0.0008195559
#> 16: 2.387103e-01 0.0008195559
#> 17: 3.677148e-07 0.0008195559
#> 18: 5.411888e-01 0.0008195559
```
