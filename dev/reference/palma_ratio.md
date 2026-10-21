# Palma Ratio

Calculates the Palma Ratio of a given accessibility distribution.
Originally defined as the income share of the richest 10% of a
population divided by the income share of the poorest 40%, this measure
has been adapted in transport planning as the average accessibility of
the richest 10% divided by the average accessibility of the poorest 40%.

## Usage

``` r
palma_ratio(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  income,
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
  and any others specified in `population` and `income`.

- opportunity:

  A string. The name of the column in `accessibility_data` with the
  accessibility levels to be considered when calculating inequality
  levels.

- population:

  A string. The name of the column in `sociodemographic_data` with the
  number of people in each cell. Used to weigh accessibility levels when
  calculating inequality.

- income:

  A string. The name of the column in `sociodemographic_data` with the
  income variable that should be used to classify the population in
  socioeconomic groups. Please note that this variable should describe
  income per capita (e.g. mean income per capita, household income per
  capita, etc), instead of the total amount of income in each cell.

- group_by:

  A `character` vector. When not `character(0)` (the default), indicates
  the `accessibility_data` columns that should be used to group the
  inequality estimates by. For example, if `accessibility_data` includes
  a `scenario` column that identifies distinct scenarios that each
  accessibility estimates refer to (e.g. before and after a transport
  policy intervention), passing `"scenario"` to this parameter results
  in inequality estimates grouped by scenario.

## Value

A data frame containing the inequality estimates for the study area.

## See also

Other equity:
[`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md),
[`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md),
[`gini_index()`](https://ipea.github.io/accessibility/dev/reference/gini_index.md),
[`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md)

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

palma <- palma_ratio(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population",
  income = "income_per_capita"
)
palma
#>    palma_ratio
#>          <num>
#> 1:    3.800465
```
