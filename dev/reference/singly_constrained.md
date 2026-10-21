# Singly constrained accessibility

Allocates opportunities at each destination proportionally based on
travel impedance and population at the origin. Uses the logic of
Wilson's single constraint. Returns values in the unit of 'demand'.
Internal helper function used by
[`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md)
when `constraint = "singly"`.

## Value

A `data.table`/`data.frame` with results (structure mirrors the
wrapper).

## Examples

``` r
NULL
#> NULL
```
