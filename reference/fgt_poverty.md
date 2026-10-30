# Foster-Greer-Thorbecke (FGT) poverty measures

Calculates the FGT metrics, a family of poverty measures originally
proposed by Foster et al. (1984) that capture the extent and severity of
poverty within an accessibility distribution. The FGT family is composed
of three measures that differ based on the \\\alpha\\ parameter used to
calculate them (either 0, 1 or 2) and which also changes their
interpretation. Please see the details section for more information on
the interpretation of the measures.

## Usage

``` r
fgt_poverty(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  poverty_line,
  poor_below_threshold = TRUE,
  group_by = character(0)
)
```

## Arguments

- accessibility_data:

  A data frame. The accessibility levels whose poverty levels should be
  calculated. Must contain the columns `id` and any others specified in
  `opportunity`.

- sociodemographic_data:

  A data frame. The distribution of sociodemographic characteristics of
  the population in the study area cells. Must contain the columns `id`
  and any others specified in `population`.

- opportunity:

  A string. The name of the column in `accessibility_data` with the
  accessibility levels to be considered when calculating accessibility
  poverty.

- population:

  A string. The name of the column in `sociodemographic_data` with the
  number of people in each cell. Used to weigh accessibility levels when
  calculating poverty.

- poverty_line:

  A `numeric`. The poverty line below which individuals are considered
  to be in accessibility poverty.

- poor_below_threshold:

  A logical. If `TRUE` (default) the observations below the poverty line
  are considered to be poor. This is the correct approach for primal
  accessibility measures (e.g. cumulative accessibility). If `FALSE`,
  then observations above the poverty line are considered to be poor.
  This is the correct approach for dual accessibility measures (e.g.
  travel time to the closest facility). When set to `FALSE`, FGT 1 and 2
  do not have an upper bound.

- group_by:

  A `character` vector. When not `character(0)` (the default), indicates
  the `accessibility_data` columns that should be used to group the
  poverty estimates by. For example, if `accessibility_data` includes a
  `race` column that specifies the racial category of the population
  (e.g. `"black"` and `"white"`) that each entry refers to, passing
  `"race"` to this parameter results in poverty estimates grouped by
  race.

## Value

A data frame containing the three poverty estimates (FGT0, FGT1 and
FGT2) for the study area.

## Interpretation of FGT measures

With a poverty line \\z\\, the FGT measures are calculated as the
population-weighted average of \\g_i^\alpha\\, in which \\g_i\\ is the
normalised shortfall of each observation \\i\\ with accessibility
\\y_i\\: \\g_i = (z - y_i) / z\\ if \\y_i \< z\\ and 0 otherwise. When
`poor_below_threshold` is `FALSE`, \\g_i\\ is instead the normalised
excess \\(y_i - z) / z\\ if \\y_i \> z\\, and 0 otherwise. The
interpretation of each measure depends on the \\\alpha\\ parameter:

- with \\\alpha = 0\\ (FGT0) the measure captures the *incidence* (or
  extent) of poverty as a simple headcount - i.e. the proportion of
  people in poverty;

- with \\\alpha = 1\\ (FGT1) the measure, also known as the "poverty gap
  index", captures the *depth* (or intensity) of poverty as the average
  normalised shortfall from the poverty line, calculated over the whole
  population (people not in poverty have a shortfall of 0);

- with \\\alpha = 2\\ (FGT2) the measure, also known as the "squared
  poverty gap index", captures the *severity* of poverty. Squaring the
  shortfalls gives more weight to the people furthest from the poverty
  line, which makes the measure sensitive to inequality among the poor.

A value of 0 indicates that no one is in poverty. When
`poor_below_threshold` is `TRUE`, FGT values range from 0 to 1: FGT0 is
1 when everyone is below the poverty line, and FGT1 and FGT2 are 1 only
when everyone has an accessibility of 0. When `poor_below_threshold` is
`FALSE`, FGT0 still ranges from 0 to 1, but FGT1 and FGT2 have no upper
bound: they can be greater than 1 (e.g. when travel costs are more than
twice the poverty line) and are `Inf` if any accessibility value is
`Inf`. This happens, for example, with the travel costs of origins that
can't reach the required opportunities, as returned by
[`cost_to_closest()`](https://ipea.github.io/accessibility/reference/cost_to_closest.md).
The function raises a warning in this case, and these values should be
replaced by a maximum travel cost (e.g. the highest cost in the travel
matrix) before calculating the FGT measures.

## References

Foster J, Greer J, Thorbecke E (1984). “A Class of Decomposable Poverty
Measures.” *Econometrica*, **52**(3), 761–766. ISSN 0012-9682.
[doi:10.2307/1913475](https://doi.org/10.2307/1913475) . 1913475.

## See also

Other equity:
[`concentration_index()`](https://ipea.github.io/accessibility/reference/concentration_index.md),
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

poverty <- fgt_poverty(
  accessibility_data = access,
  opportunity = "jobs",
  sociodemographic_data = land_use_data,
  population = "population",
  poverty_line = 50000
)
poverty
#>         FGT0      FGT1      FGT2
#>        <num>     <num>     <num>
#> 1: 0.3923817 0.1776241 0.1010123
```
