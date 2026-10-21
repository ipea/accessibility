# accessibility

[![CRAN
status](https://www.r-pkg.org/badges/version/accessibility)](https://CRAN.R-project.org/package=accessibility)
[![rcmdcheck](https://github.com/ipea/accessibility/workflows/rcmdcheck/badge.svg)](https://github.com/ipea/accessibility/actions)
[![CRAN/METACRAN Total
downloads](https://cranlogs.r-pkg.org/badges/grand-total/accessibility?color=yellow)](https://CRAN.R-project.org/package=accessibility)
[![Codecov test
coverage](https://codecov.io/gh/ipea/accessibility/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ipea/accessibility?branch=main)
[![Lifecycle:
stable](https://lifecycle.r-lib.org/articles/figures/lifecycle-stable.svg)](https://lifecycle.r-lib.org/articles/stages.html)

**accessibility** offers a set of fast and convenient functions to help
conducting accessibility analyses. Given a pre-computed travel cost
matrix and a land use dataset (containing the location of jobs,
healthcare and population, for example), the package allows one to
calculate accessibility levels and accessibility poverty and inequality.
The package covers the majority of the most commonly used accessibility
measures (such as cumulative opportunities, gravity-based and floating
catchment areas methods), some cutting edge measures proposed in the
literature (e.g. balancing cost and constrained accessibility), as well
as the most frequently used inequality and poverty metrics (such as the
Palma ratio, the concentration and Theil indices and the FGT family of
measures).

## Installation

Stable version:

``` r

install.packages("accessibility")
```

Development version:

``` r

# install.packages("remotes")
remotes::install_github("ipea/accessibility")
```

## Usage

This section aims to present a very brief overview of some of the
packages’ features. Fore more details please read the vignettes:

- [Introduction to **accessibility**: calculating accessibility
  measures](https://ipea.github.io/accessibility/articles/accessibility.html)
- [Decay
  functions](https://ipea.github.io/accessibility/articles/decay_functions.html)
- [Calculating accessibility inequality and
  poverty](https://ipea.github.io/accessibility/articles/inequality_and_poverty.html)

To calculate accessibility levels, one simply needs a pre-calculated
travel matrix and some land use data. Below we showcase some of the
available functions:

``` r

library(accessibility)

data_dir <- system.file("extdata", package = "accessibility")
travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

cum_cutoff <- cumulative_cutoff(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  cutoff = 30
)
head(cum_cutoff)
#>                 id  jobs
#>             <char> <int>
#> 1: 89a881a5a2bffff 14561
#> 2: 89a881a5a2fffff 29452
#> 3: 89a881a5a67ffff 16647
#> 4: 89a881a5a6bffff 10700
#> 5: 89a881a5a6fffff  6669
#> 6: 89a881a5b03ffff 37029

grav <- gravity(
  travel_matrix,
  land_use_data,
  opportunity = "schools",
  travel_cost = "travel_time",
  decay_function = decay_exponential(decay_value = 0.2)
)
head(grav)
#>                 id    schools
#>             <char>      <num>
#> 1: 89a88cdb57bffff 0.03041853
#> 2: 89a88cdb597ffff 1.15549493
#> 3: 89a88cdb5b3ffff 0.56519126
#> 4: 89a88cdb5cfffff 0.19852152
#> 5: 89a88cd909bffff 0.41378042
#> 6: 89a88cd90b7ffff 0.95737555

fca <- floating_catchment_area(
  travel_matrix,
  land_use_data,
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population",
  method = "2sfca",
  decay_function = decay_binary(cutoff = 50)
)
head(fca)
#>                 id      jobs
#>             <char>     <num>
#> 1: 89a88cdb57bffff 0.4278111
#> 2: 89a88cdb597ffff 0.3863614
#> 3: 89a88cdb5b3ffff 0.4501725
#> 4: 89a88cdb5cfffff 0.5366707
#> 5: 89a88cd909bffff 0.4280401
#> 6: 89a88cd90b7ffff 0.5176583
```

Calculating inequality and poverty levels is equally easy. Below we use
the previously calculated cumulative accessibility dataset to show some
of the available inequality and poverty functions:

``` r

palma <- palma_ratio(
  cum_cutoff,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population",
  income = "income_per_capita"
)
palma
#>    palma_ratio
#>          <num>
#> 1:    3.800465

poverty <- fgt_poverty(
  cum_cutoff,
  sociodemographic_data = land_use_data,
  opportunity = "jobs",
  population = "population",
  poverty_line = 95368
)
poverty
#>         FGT0      FGT1      FGT2
#>        <num>     <num>     <num>
#> 1: 0.5745378 0.3277383 0.2218769
```

## Related work:

- [r5r](https://github.com/ipea/r5r): Rapid Realistic Routing with R5 in
  R
- [tracc](https://github.com/jamaps/tracc): Transport accessibility
  measures in Python
- [access](https://access.readthedocs.io/en/latest/): Spatial Access for
  PySAL
- [aceso](https://github.com/tetraptych/aceso): a lightweight Python
  package for measuring spatial accessibility

## Acknowledgement [![IPEA](reference/figures/ipea_logo.png)](https://www.ipea.gov.br)

**accessibility** is developed by a team at the Institute for Applied
Economic Research (Ipea), Brazil.
