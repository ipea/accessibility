# Negative exponential decay function

Returns a negative exponential weighting function to be used inside
accessibility calculating functions.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_exponential(decay_value)
```

## Arguments

- decay_value:

  A `numeric` vector. The calibration parameters that, when multiplied
  by the travel cost, are used as the exponent of `e` in the negative
  exponential function.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## See also

Other decay functions:
[`decay_binary()`](https://ipea.github.io/accessibility/dev/reference/decay_binary.md),
[`decay_linear()`](https://ipea.github.io/accessibility/dev/reference/decay_linear.md),
[`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md),
[`decay_power()`](https://ipea.github.io/accessibility/dev/reference/decay_power.md),
[`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md)

## Examples

``` r
weighting_function <- decay_exponential(decay_value = 0.1)

weighting_function(c(20, 30))
#> $`0.1`
#> [1] 0.13533528 0.04978707
#> 

weighting_function <- decay_exponential(decay_value = c(0.1, 0.2))

weighting_function(c(20, 30))
#> $`0.1`
#> [1] 0.13533528 0.04978707
#> 
#> $`0.2`
#> [1] 0.018315639 0.002478752
#> 
```
