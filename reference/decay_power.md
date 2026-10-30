# Inverse power decay function

Returns an inverse power weighting function to be used inside
accessibility calculating functions.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_power(decay_value)
```

## Arguments

- decay_value:

  A `numeric` vector. The calibration parameters to be used as the
  exponents in the inverse power function.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## See also

Other decay functions:
[`decay_binary()`](https://ipea.github.io/accessibility/reference/decay_binary.md),
[`decay_exponential()`](https://ipea.github.io/accessibility/reference/decay_exponential.md),
[`decay_linear()`](https://ipea.github.io/accessibility/reference/decay_linear.md),
[`decay_logistic()`](https://ipea.github.io/accessibility/reference/decay_logistic.md),
[`decay_stepped()`](https://ipea.github.io/accessibility/reference/decay_stepped.md)

## Examples

``` r
weighting_function <- decay_power(decay_value = 0.1)

weighting_function(c(20, 35))
#> $`0.1`
#> [1] 0.7411344 0.7007986
#> 

weighting_function <- decay_power(decay_value = c(0.1, 0.2))

weighting_function(c(20, 35))
#> $`0.1`
#> [1] 0.7411344 0.7007986
#> 
#> $`0.2`
#> [1] 0.5492803 0.4911186
#> 
```
