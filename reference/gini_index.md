# Gini Index

Calculates the Gini Index of a given accessibility distribution.

## Usage

``` r
gini_index(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
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
  and any others specified in `population`.

- opportunity:

  A string. The name of the column in `accessibility_data` with the
  accessibility levels to be considered when calculating inequality
  levels.

- population:

  A string. The name of the column in `sociodemographic_data` with the
  number of people in each cell. Used to weigh accessibility levels when
  calculating inequality.

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
[`concentration_index()`](https://ipea.github.io/accessibility/reference/concentration_index.md),
[`fgt_poverty()`](https://ipea.github.io/accessibility/reference/fgt_poverty.md),
[`palma_ratio()`](https://ipea.github.io/accessibility/reference/palma_ratio.md),
[`theil_t()`](https://ipea.github.io/accessibility/reference/theil_t.md)

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

gini <- gini_index(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population"
)
gini
#>    gini_index
#>         <num>
#> 1:  0.4715251
```
