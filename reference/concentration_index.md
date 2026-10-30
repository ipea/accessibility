# Concentration Index

Calculates the Concentration Index (CI) of a given accessibility
distribution. This measure estimates the extent to which accessibility
inequalities are systematically associated with individuals'
socioeconomic levels. CI values can theoretically vary between -1 and +1
(when all accessibility is concentrated in the most or in the least
disadvantaged person, respectively). Negative values indicate that
inequalities favor the poor, while positive values indicate a pro-rich
bias. The function supports calculating the standard relative CI and the
corrected CI, as proposed by Erreygers (2009) .

## Usage

``` r
concentration_index(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  income,
  type,
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
  income variable that should be used to sort the population from the
  least to the most privileged. Please note that this variable should
  describe income per capita (e.g. mean income per capita, household
  income per capita, etc), instead of the total amount of income in each
  cell. Also note that, while income is generally used to rank
  population groups, any variable that can be used to describe one's
  socioeconomic status, such as education level, can be passed to this
  argument, as long as it can be numerically ordered (in which higher
  values denote higher socioeconomic status).

- type:

  A string. Which type of Concentration Index to calculate. Current
  available options are `"standard"` and `"corrected"`.

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

## References

Erreygers G (2009). “Correcting the Concentration Index.” *Journal of
Health Economics*, **28**(2), 504–515. ISSN 0167-6296.
[doi:10.1016/j.jhealeco.2008.02.003](https://doi.org/10.1016/j.jhealeco.2008.02.003)
.

## See also

Other equity:
[`fgt_poverty()`](https://ipea.github.io/accessibility/reference/fgt_poverty.md),
[`gini_index()`](https://ipea.github.io/accessibility/reference/gini_index.md),
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

ci <- concentration_index(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population",
  income = "income_per_capita",
  type = "corrected"
)
ci
#>    concentration_index
#>                  <num>
#> 1:           0.3346194
```
