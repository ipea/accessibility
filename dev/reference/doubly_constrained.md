# Doubly constrained accessibility

Calculates accessibility using Wilson's doubly-constrained gravity
model. This measure allocates flows between origins and destinations
such that origin totals equal demand and destination totals equal
supply. Note: this is an internal helper function used by
[`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md)
when `constraint = "doubly"`.

## Value

A `data.table`/`data.frame` with origin-destination flows, balancing
factors (`A_i`, `B_j`), and doubly-constrained weights (`kappa_doubly`).

## Examples

``` r
NULL
#> NULL
```
