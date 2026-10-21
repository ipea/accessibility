# Stepped decay function

Returns a stepped weighting function to be used inside accessibility
calculating functions.

This function is generic over any kind of numeric travel cost, such as
distance, time and money.

## Usage

``` r
decay_stepped(steps, weights)
```

## Arguments

- steps:

  A `numeric` vector or a list of `numeric` vectors. The travel cost
  steps, in ascending order. Please do not include travel cost 0 as a
  step: this is already handled by the function.

- weights:

  A `numeric` vector with same length as `steps` or a list of `numeric`
  vectors whose lengths are equal to the lengths of the elements of same
  index in `steps`. The values, between 0 and 1, that the function
  assumes at each step. Please do not include weight 1 as the first
  value: this is already handled by the function. The function considers
  the steps' intervals "open on the right", meaning that the function
  assumes the step value at the actual step, not right after it. Please
  see the illustrative examples for effects of this assumption on the
  results.

## Value

A `function` that takes a generic travel cost vector (`numeric`) as an
input and returns a `list` of weight vectors (a list of `numeric`
vectors, named after the arguments passed to the decay function).

## Details

When both `steps` and `weights` parameters are given `list`s, their
content are matched element-wise to define each stepped weighting
function

- i.e. the first element of `steps` is matched to the first element of
  `weights`, the second element of `steps` is matched to the second of
  `weights`, etc. When using a function created with `decay_stepped()`,
  the output is named after the combination of steps (`"s"`) and weights
  (`"w"`)

- e.g. given the steps `c(10, 20, 30)` and the weights
  `c(0.66, 0.33, 0)`, the output will be named
  `"s(10,20,30);w(0.66,0.33,0)"`.

## See also

Other decay functions:
[`decay_binary()`](https://ipea.github.io/accessibility/dev/reference/decay_binary.md),
[`decay_exponential()`](https://ipea.github.io/accessibility/dev/reference/decay_exponential.md),
[`decay_linear()`](https://ipea.github.io/accessibility/dev/reference/decay_linear.md),
[`decay_logistic()`](https://ipea.github.io/accessibility/dev/reference/decay_logistic.md),
[`decay_power()`](https://ipea.github.io/accessibility/dev/reference/decay_power.md)

## Examples

``` r
weighting_function <- decay_stepped(
  c(10, 20, 30, 40),
  weights = c(0.75, 0.5, 0.25, 0)
)

weighting_function(c(5, 25, 35, 45))
#> $`s(10,20,30,40);w(0.75,0.5,0.25,0)`
#> [1] 1.00 0.50 0.25 0.00
#> 

weighting_function <- decay_stepped(
  list(c(10, 20, 30, 40), c(10, 20, 30, 40)),
  weights = list(c(0.75, 0.5, 0.25, 0), c(0.8, 0.6, 0.4, 0.2))
)

weighting_function(c(5, 25, 35, 45))
#> $`s(10,20,30,40);w(0.75,0.5,0.25,0)`
#> [1] 1.00 0.50 0.25 0.00
#> 
#> $`s(10,20,30,40);w(0.8,0.6,0.4,0.2)`
#> [1] 1.0 0.6 0.4 0.2
#> 

# intervals are open on the right, so the values change exactly at each step
weighting_function(c(0, 10, 20, 30, 40))
#> $`s(10,20,30,40);w(0.75,0.5,0.25,0)`
#> [1] 1.00 0.75 0.50 0.25 0.00
#> 
#> $`s(10,20,30,40);w(0.8,0.6,0.4,0.2)`
#> [1] 1.0 0.8 0.6 0.4 0.2
#> 
```
