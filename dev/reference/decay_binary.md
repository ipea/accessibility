# Binary (a.k.a. step) decay function

Returns a binary weighting function (frequently used to calculate
cumulative opportunities measures) to be used inside accessibility
calculating functions.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_binary(cutoff)
```

## Arguments

- cutoff:

  A `numeric` vector. The numbers indicating the travel cost cutoffs.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## See also

Other decay functions:
[`decay_exponential()`](https://ipea.github.io/accessibility/dev/reference/decay_exponential.md),
[`decay_linear()`](https://ipea.github.io/accessibility/dev/reference/decay_linear.md),
[`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md),
[`decay_power()`](https://ipea.github.io/accessibility/dev/reference/decay_power.md),
[`decay_stepped()`](https://ipea.github.io/accessibility/dev/reference/decay_stepped.md)

## Examples

``` r
weighting_function <- decay_binary(cutoff = 30)

weighting_function(c(20, 35))
#> $`30`
#> [1] 1 0
#> 

weighting_function <- decay_binary(cutoff = c(30, 45))

weighting_function(c(20, 35))
#> $`30`
#> [1] 1 0
#> 
#> $`45`
#> [1] 1 1
#> 
```
