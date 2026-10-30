# Linear decay function

Returns a linear weighting function to be used inside accessibility
calculating functions.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_linear(cutoff)
```

## Arguments

- cutoff:

  A `numeric` vector. Indicates the travel cost cutoffs until which the
  weighting factor decays linearly. From this point onward the weight is
  equal to 0. Must be greater than 0.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## See also

Other decay functions:
[`decay_binary()`](https://ipea.github.io/accessibility/reference/decay_binary.md),
[`decay_exponential()`](https://ipea.github.io/accessibility/reference/decay_exponential.md),
[`decay_logistic()`](https://ipea.github.io/accessibility/reference/decay_logistic.md),
[`decay_power()`](https://ipea.github.io/accessibility/reference/decay_power.md),
[`decay_stepped()`](https://ipea.github.io/accessibility/reference/decay_stepped.md)

## Examples

``` r
weighting_function <- decay_linear(cutoff = 30)

weighting_function(c(20, 35))
#> $`30`
#> [1] 0.3333333 0.0000000
#> 

weighting_function <- decay_linear(cutoff = c(30, 45))

weighting_function(c(20, 35))
#> $`30`
#> [1] 0.3333333 0.0000000
#> 
#> $`45`
#> [1] 0.5555556 0.2222222
#> 
```
