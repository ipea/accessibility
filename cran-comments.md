── R CMD check results ──────────────────────────────── accessibility 2.0.0 ────
Duration: 1m 57.1s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## New features

- New function `constrained_accessibility()`, which implements the family of 
constrained accessibility measures proposed in \url{https://doi.org/10.1371/journal.pone.0335951}

## Minor changes

- The function `fgt_poverty()` has a new argument `poor_below_threshold`. when
set to `TRUE` (default,) the observations below the poverty line are considered 
to be poor. This is the correct approach for primal accessibility measures (e.g.
cumulative accessibility). If `FALSE`, then observations above the poverty line 
are considered to be poor. This is the correct approach for dual accessibility 
measures (e.g. travel time to the closest facility). When set to `FALSE`, FGT 1 
and 2 do not have an upper bound.
