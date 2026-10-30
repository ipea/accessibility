# Logistic decay function

Returns a logistic weighting function (in which the weights follow the
distribution of a reversed cumulative logistic curve) to be used inside
accessibility calculating functions. The logistic curve is parameterized
with the cutoff that sets its inflection point and the standard
deviation that sets its steepness.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_logistic(cutoff, sd)
```

## Arguments

- cutoff:

  A `numeric` vector. The cost value that serves as the inflection point
  of the cumulative logistic curve.

- sd:

  A `numeric` vector with same length as `cutoff`. The standard
  deviation of the logistic curve. Values near 0 result in weighting
  curves that approximate binary decay, while higher values tend to
  linearize the decay.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## Details

When using a function created with `decay_logistic()`, the output is
named after the combination of cutoffs (`"c"`) and standard deviations
(`"sd"`) - e.g. given the cutoffs `c(30, 40)` and the standard
deviations `c(10, 20)`, the first element of the output will be named
`"c30;sd10"` and the second will be named `"c40;sd20"`. This function
uses the adjusted logistic decay curve proposed by Bauer and Groneberg
(2016) , in which the condition f(0) = 1 is met (i.e. the weight of an
opportunity whose cost to reach is 0 is 1).

## References

Bauer J, Groneberg DA (2016). “Measuring Spatial Accessibility of Health
Care Providers – Introduction of a Variable Distance Decay Function
within the Floating Catchment Area (FCA) Method.” *PLOS ONE*, **11**(7),
e0159148. ISSN 1932-6203.
[doi:10.1371/journal.pone.0159148](https://doi.org/10.1371/journal.pone.0159148)
.

## See also

Other decay functions:
[`decay_binary()`](https://ipea.github.io/accessibility/reference/decay_binary.md),
[`decay_exponential()`](https://ipea.github.io/accessibility/reference/decay_exponential.md),
[`decay_linear()`](https://ipea.github.io/accessibility/reference/decay_linear.md),
[`decay_power()`](https://ipea.github.io/accessibility/reference/decay_power.md),
[`decay_stepped()`](https://ipea.github.io/accessibility/reference/decay_stepped.md)

## Examples

``` r
weighting_function <- decay_logistic(cutoff = 30, sd = 5)

weighting_function(c(0, 30, 45, 60))
#> $`c30;sd5`
#> [1] 1.000000e+00 5.000094e-01 4.314804e-03 1.877853e-05
#> 

weighting_function <- decay_logistic(cutoff = c(30, 45), sd = c(5, 10))

weighting_function(c(0, 30, 45, 60))
#> $`c30;sd5`
#> [1] 1.000000e+00 5.000094e-01 4.314804e-03 1.877853e-05
#> 
#> $`c45;sd10`
#> [1] 1.00000000 0.93850470 0.50014263 0.06178056
#> 
```
