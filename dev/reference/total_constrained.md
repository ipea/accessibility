# Total constrained accessibility

Allocates total opportunities in the region proportionally based on
travel impedance. Uses the logic of a total (or unconstrained by
Wilson's terms) constraint. Returns values in units of 'supply' (i.e.,
opportunities) if `active = TRUE` and returns values in units of demand'
(i.e., population) if `active = FALSE`.

## Value

A `data.table`/`data.frame` with results (structure mirrors the
wrapper).

## Details

Internal helper used by
[`constrained_accessibility()`](https://ipea.github.io/accessibility/dev/reference/constrained_accessibility.md)
when `constraint = "total"`.

## Examples

``` r
NULL
#> NULL
```
