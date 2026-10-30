# Theil T Index

Calculates the Theil T Index of a given accessibility distribution.
Values range from 0 (when all individuals have exactly the same
accessibility levels) to the natural log of *n*, in which *n* is the
number of individuals in the accessibility dataset. If the individuals
can be classified into mutually exclusive and completely exhaustive
groups, the index can be decomposed into a between-groups inequality
component and a within-groups component.

## Usage

``` r
theil_t(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  socioeconomic_groups = NULL,
  group_by = character(0)
)
```

## Arguments

- accessibility_data:

  A data frame. The accessibility levels whose inequality should be
  calculated. Must contain the columns `id` and any others specified in
  `opportunity`.

- sociodemographic_data:

  A data frame. The distribution of sociodemographic characteristics of
  the population in the study area cells. Must contain the columns `id`
  and any others specified in `population` and `socioeconomic_groups`.

- opportunity:

  A string. The name of the column in `accessibility_data` with the
  accessibility levels to be considered when calculating inequality
  levels.

- population:

  A string. The name of the column in `sociodemographic_data` with the
  number of people in each cell. Used to weigh accessibility levels when
  calculating inequality.

- socioeconomic_groups:

  A string. The name of the column in `sociodemographic_data` whose
  values identify the socioeconomic groups that should be used to
  calculate the between- and within-groups inequality levels. If `NULL`
  (the default), between- and within-groups components are not
  calculated and only the total aggregate inequality is returned.

- group_by:

  A `character` vector. When not `character(0)` (the default), indicates
  the `accessibility_data` columns that should be used to group the
  inequality estimates by. For example, if `accessibility_data` includes
  a `scenario` column that identifies distinct scenarios that each
  accessibility estimates refer to (e.g. before and after a transport
  policy intervention), passing `"scenario"` to this parameter results
  in inequality estimates grouped by scenario.

## Value

If `socioeconomic_groups` is `NULL`, a data frame containing the total
Theil T estimates for the study area. If not, a list containing three
dataframes: one summarizing the total inequality and the between- and
within-groups components, one listing the contribution of each group to
the between-groups component and another listing the contribution of
each group to the within-groups component.

## Details

Observations with no access contribute 0 to the index, following the
usual convention that `0 * log(0) = 0`. If no one has access to any
opportunity (i.e. the average accessibility is 0), the index is
undefined and `NA` is returned.

## See also

Other equity:
[`concentration_index()`](https://ipea.github.io/accessibility/reference/concentration_index.md),
[`fgt_poverty()`](https://ipea.github.io/accessibility/reference/fgt_poverty.md),
[`gini_index()`](https://ipea.github.io/accessibility/reference/gini_index.md),
[`palma_ratio()`](https://ipea.github.io/accessibility/reference/palma_ratio.md)

## Examples

``` r
data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

access <- cumulative_cutoff(
  travel_matrix,
  land_use_data,
  cutoff = 30,
  opportunity = "jobs",
  travel_cost = "travel_time"
)

ti <- theil_t(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population"
)
ti
#>      theil_t
#>        <num>
#> 1: 0.3616631

# to calculate inequality between and within income deciles, we pass
# "income_decile" to socioeconomic_groups.
# some cells, however, are classified as in the decile NA because their
# income per capita is NaN, as they don't have any population. we filter
# these cells from our accessibility data, otherwise the output would include
# NA values (note that subsetting the data like this doesn't affect the
# assumption that groups are completely exhaustive, because cells with NA
# income decile don't have any population)

na_decile_ids <- land_use_data[is.na(land_use_data$income_decile), ]$id
access <- access[! access$id %in% na_decile_ids, ]
sociodem_data <- land_use_data[! land_use_data$id %in% na_decile_ids, ]

ti <- theil_t(
  access,
  sociodemographic_data = sociodem_data,
  opportunity = "jobs",
  population = "population",
  socioeconomic_groups = "income_decile"
)
ti
#> $summary
#>        component     value share_of_total
#>           <char>     <num>          <num>
#> 1: between_group 0.1280753      0.3541287
#> 2:  within_group 0.2335878      0.6458713
#> 3:         total 0.3616631      1.0000000
#> 
#> $within_group_component
#>     income_decile       value share_of_component
#>            <fctr>       <num>              <num>
#>  1:             1 0.009181454         0.03930622
#>  2:             2 0.011413697         0.04886255
#>  3:             3 0.019320622         0.08271246
#>  4:             4 0.023606928         0.10106232
#>  5:             5 0.031470429         0.13472633
#>  6:             6 0.023539337         0.10077296
#>  7:             7 0.033329635         0.14268567
#>  8:             8 0.032585905         0.13950173
#>  9:             9 0.020299031         0.08690107
#> 10:            10 0.028840780         0.12346868
#> 
#> $between_group_component
#>     income_decile        value
#>            <fctr>        <num>
#>  1:             1 -0.037573783
#>  2:             2 -0.036276865
#>  3:             3 -0.031829123
#>  4:             4 -0.021600054
#>  5:             5 -0.009938574
#>  6:             6 -0.004401762
#>  7:             7  0.025936879
#>  8:             8  0.042240708
#>  9:             9  0.075742415
#> 10:            10  0.125775443
#> 
```
