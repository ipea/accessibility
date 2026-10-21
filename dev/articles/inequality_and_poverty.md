# Calculating accessibility inequality and poverty

**accessibility** not only includes functions to calculate accessibility
levels from travel time matrices and land use datasets, but also to
calculate accessibility inequality and poverty from an accessibility
distribution. This vignette briefly presents these functions.

## Demonstration on sample data

We first need to calculate the accessibility levels that we are going to
use in this demonstration. To do so, we use the
[`cumulative_cutoff()`](https://ipea.github.io/accessibility/dev/reference/cumulative_cutoff.md)
function and the sample data included in the package.

``` r

library(accessibility)

data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

access <- cumulative_cutoff(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  cutoff = 30
)
head(access)
#>                 id  jobs
#>             <char> <int>
#> 1: 89a881a5a2bffff 14561
#> 2: 89a881a5a2fffff 29452
#> 3: 89a881a5a67ffff 16647
#> 4: 89a881a5a6bffff 10700
#> 5: 89a881a5a6fffff  6669
#> 6: 89a881a5b03ffff 37029
```

The functions we’ll be demonstrating in this section take much of the
same information as input, including:

- the accessibility distribution;
- a sociodemographic dataset containing information such as the
  distribution of people in the study area and their income;
- the name of the column in the accessibility dataset with the
  opportunities whose accessibility should be considered in the
  calculation; and
- the name of the column in the sociodemographic dataset with the number
  of people in each cell, used to weigh accessibility levels when
  calculating inequality/poverty.

### Palma Ratio

[`palma_ratio()`](https://ipea.github.io/accessibility/dev/reference/palma_ratio.md)
calculates the Palma Ratio of a given accessibility distribution.
Originally defined as the income share of the wealthiest 10% of a
population divided by the income share of the poorest 40%, this measure
has been adapted in transport planning as the average accessibility of
the wealthiest 10% divided by the average accessibility of the poorest
40%. Palma Ratio values higher than 1 indicate a scenario in which the
wealthiest population has higher accessibility levels than the poorest,
whereas values lower than 1 indicate the opposite situation.

This function includes an additional `income` parameter, used to list
the column in the sociodemographic dataset with the income variable that
should be used to classify the population in socioeconomic groups.
Please note that this variable should describe income per capita
(e.g. mean income per capita, household income per capita, etc), instead
of the total amount of income in each cell.

``` r

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

### Gini Index

[`gini_index()`](https://ipea.github.io/accessibility/dev/reference/gini_index.md)
calculates the Gini Index of a given accessibility distribution.
Probably the most frequently used inequality measure in transport
planning, this index estimates how much a distribution deviates from a
hypothetical situation in which everyone has the exact same
accessibility conditions. Gini Index values range from 0 to 1. A value
of 0 indicates a scenario of perfect equality, in which everyone has the
same accessibility levels, whereas a value of 1 indicates a scenario of
perfect inequality, in which the accessibility levels in a study area
are all concentrated into a single cell.

``` r

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

### Concentration Index

[`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md)
calculates the Concentration Index (CI) of a given accessibility
distribution. This indicator estimates the extent to which accessibility
inequalities are systematically associated with individuals’
socioeconomic levels. CI values can theoretically vary between -1 and 1
(when all accessibility is concentrated in the most or in the least
disadvantaged cell, respectively). Negative values indicate that
inequalities favor the poor, while positive values indicate a pro-rich
bias.

Just like
[`palma_ratio()`](https://ipea.github.io/accessibility/dev/reference/palma_ratio.md),
this function includes an `income` parameter to indicate which variable
from the sociodemographic dataset should be used to rank the population
from the least to the most privileged groups. Unlike the Palma Ratio
function, however, any variable that can be used to describe one’s
socioeconomic status, such as education level, for example, can be
passed to this argument, as long as it can be numerically ordered (in
which higher values denote higher socioeconomic status).

[`concentration_index()`](https://ipea.github.io/accessibility/dev/reference/concentration_index.md)
also includes a `type` parameter, used to indicate which Concentration
Index to calculate. This parameter currently supports two values,
`"standard"` and `"corrected"`, which respectively identify the standard
relative CI and the corrected CI, proposed by Erreygers (2009).

``` r

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

### Theil T

[`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md)
calculates the Theil T Index of a given accessibility distribution.
Values range from 0 (when all individuals have exactly the same
accessibility levels) to the natural log of *n*, in which *n* is the
number of individuals in the accessibility dataset.

If the individuals can be classified into mutually exclusive and
completely exhaustive groups (i.e. into groups that do not overlap and
cover the entire population), the index can be decomposed into a
between- and a within-groups inequality component. The function includes
a `socioeconomic_groups` parameter to indicate which variable from the
sociodemographic dataset should be used identify the socioeconomic
groups used to calculate these components.

Please note that the output of
[`theil_t()`](https://ipea.github.io/accessibility/dev/reference/theil_t.md)
varies based on the value of `socioeconomic_groups`. If `NULL` (the
default), the between- and within-groups components are not calculated,
and the function returns a data frame containing only the total
aggregate inequality for the study area. If `socioeconomic_groups` is
not `NULL`, however, the function returns a list containing three
dataframes: one summarizing the total inequality and the between- and
within-groups components, one listing the contribution of each group to
the between-groups component and another listing the contribution of
each group to the within-groups component. Both behaviors are shown
below.

``` r

theil_without_groups <- theil_t(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population"
)
theil_without_groups
#>      theil_t
#>        <num>
#> 1: 0.3616631

# some cells are classified as in the decile NA because their income per capita
# is NaN, as they don't have any population. we filter these cells from our
# accessibility data, otherwise the output would include NA values (note that
# subsetting the data like this doesn't affect the assumption that groups are
# completely exhaustive, because cells with NA income decile don't have any
# population)

na_decile_ids <- land_use_data[is.na(land_use_data$income_decile), ]$id
no_na_access <- access[! access$id %in% na_decile_ids, ]
sociodem_data <- land_use_data[! land_use_data$id %in% na_decile_ids, ]

theil_with_groups <- theil_t(
  no_na_access,
  sociodemographic_data = sociodem_data,
  opportunity = "jobs",
  population = "population",
  socioeconomic_groups = "income_decile"
)
theil_with_groups
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
```

### Foster-Greer-Thorbecke (FGT) poverty measures

[`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)
calculates the FGT metrics, a family of poverty measures originally
proposed by Foster et al. (1984) that capture the incidence, depth and
severity of poverty within an accessibility distribution. The FGT family
is composed of three measures that differ based on the $`\alpha`$
parameter used to calculate them (either 0, 1 or 2) and which also
changes their interpretation:

- with $`\alpha = 0`$ (FGT0) the measure captures the incidence (or
  extent) of poverty as a simple headcount - i.e. the proportion of
  people below the poverty line;
- with $`\alpha = 1`$ (FGT1) the measure, also known as the “poverty gap
  index”, captures the depth of poverty as the average shortfall from
  the poverty line, relative to the poverty line, calculated over the
  whole population (people above the poverty line have a shortfall of
  0);
- with $`\alpha = 2`$ (FGT2) the measure, also known as the “squared
  poverty gap index”, captures the severity of poverty. By squaring the
  shortfalls, it gives more weight to the people furthest below the
  poverty line, which makes it sensitive to inequality among the poor.

This function includes an additional `poverty_line` parameter, used to
define the poverty line below which individuals are considered to be in
accessibility poverty.

``` r

poverty <- fgt_poverty(
  access,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population",
  poverty_line = 50000
)

poverty
#>         FGT0      FGT1      FGT2
#>        <num>     <num>     <num>
#> 1: 0.3923817 0.1776241 0.1010123
```

By default,
[`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)
considers that people with accessibility *below* the poverty line are
poor, which is the right approach for primal accessibility measures,
such as the number of accessible jobs. For dual measures, such as the
travel time to the closest facility calculated with
[`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md),
higher values indicate worse access, so people *above* the poverty line
should be considered poor. This is done by setting
`poor_below_threshold = FALSE`. In this case, FGT1 and FGT2 measure the
excess travel cost relative to the poverty line, so they are not bounded
by 1. In the example below, we consider that people who take more than
20 minutes to reach the closest school are in accessibility poverty.
Note that
[`cost_to_closest()`](https://ipea.github.io/accessibility/dev/reference/cost_to_closest.md)
returns `Inf` for origins that can’t reach any school in the travel
matrix, which would make FGT1 and FGT2 infinite
([`fgt_poverty()`](https://ipea.github.io/accessibility/dev/reference/fgt_poverty.md)
warns about it), so we replace these values by the longest travel time
in the travel matrix (120 minutes) beforehand.

``` r

time_to_school <- cost_to_closest(
  travel_matrix,
  land_use_data,
  opportunity = "schools",
  travel_cost = "travel_time"
)

unreachable <- is.infinite(time_to_school$travel_time)
time_to_school$travel_time[unreachable] <- 120

poverty_dual <- fgt_poverty(
  time_to_school,
  sociodemographic_data = land_use_data,
  opportunity = "travel_time",
  population = "population",
  poverty_line = 20,
  poor_below_threshold = FALSE
)

poverty_dual
#>          FGT0        FGT1       FGT2
#>         <num>       <num>      <num>
#> 1: 0.02635896 0.009283491 0.02337055
```

## References

Erreygers, Guido. 2009. “Correcting the Concentration Index.” *Journal
of Health Economics* 28 (2): 504–15.
<https://doi.org/10.1016/j.jhealeco.2008.02.003>.

Foster, James, Joel Greer, and Erik Thorbecke. 1984. “A Class of
Decomposable Poverty Measures.” *Econometrica* 52 (3): 761–66.
<https://doi.org/10.2307/1913475>.
