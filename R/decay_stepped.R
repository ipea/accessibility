#' Stepped decay function
#'
#' Returns a stepped weighting function to be used inside accessibility
#' calculating functions.
#' @template description_generic_cost
#'
#' @param steps A `numeric` vector or a list of `numeric` vectors. The travel
#'   cost steps, in ascending order. Please do not include travel cost 0 as a
#'   step: this is already handled by the function.
#' @param weights A `numeric` vector with same length as `steps` or a list of
#'   `numeric` vectors whose lengths are equal to the lengths of the elements of
#'   same index in `steps`. The values, between 0 and 1, that the function
#'   assumes at each step. Please do not include weight 1 as the first value:
#'   this is already handled by the function. The function considers the steps'
#'   intervals "open on the right", meaning that the function assumes the step
#'   value at the actual step, not right after it. Please see the illustrative
#'   examples for effects of this assumption on the results.
#'
#' @template return_decay_function
#'
#' @details When both `steps` and `weights` parameters are given `list`s, their
#'   content are matched element-wise to define each stepped weighting function
#'   - i.e. the first element of `steps` is matched to the first element of
#'   `weights`, the second element of `steps` is matched to the second of
#'   `weights`, etc. When using a function created with `decay_stepped()`, the
#'   output is named after the combination of steps (`"s"`) and weights (`"w"`)
#'   - e.g. given the steps `c(10, 20, 30)` and the weights `c(0.66, 0.33, 0)`,
#'   the output will be named `"s(10,20,30);w(0.66,0.33,0)"`.
#'
#' @family decay functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' weighting_function <- decay_stepped(
#'   c(10, 20, 30, 40),
#'   weights = c(0.75, 0.5, 0.25, 0)
#' )
#'
#' weighting_function(c(5, 25, 35, 45))
#'
#' weighting_function <- decay_stepped(
#'   list(c(10, 20, 30, 40), c(10, 20, 30, 40)),
#'   weights = list(c(0.75, 0.5, 0.25, 0), c(0.8, 0.6, 0.4, 0.2))
#' )
#'
#' weighting_function(c(5, 25, 35, 45))
#'
#' # intervals are open on the right, so the values change exactly at each step
#' weighting_function(c(0, 10, 20, 30, 40))
#'
#' @export
decay_stepped <- function(steps, weights) {
  assert_steps(steps)
  assert_weights(weights, steps)

  if (!is.list(steps)) steps <- list(steps)
  if (!is.list(weights)) weights <- list(weights)

  # duplicated (steps, weights) pairs would produce duplicated list names,
  # which are merged/double counted downstream

  step_weight_pairs <- mapply(
    function(stps, wghts) list(as.numeric(stps), as.numeric(wghts)),
    steps,
    weights,
    SIMPLIFY = FALSE
  )

  if (anyDuplicated(step_weight_pairs)) {
    cli::cli_abort(
      "Assertion on {.arg steps} and {.arg weights} failed: Must not contain
      duplicated (steps, weights) pairs.",
      call = NULL
    )
  }

  steps <- lapply(steps, function(stps) c(0, stps))
  weights <- lapply(weights, function(wghts) c(1, wghts))

  weighting_function <- function(travel_cost) {
    weights_list <- mapply(
      stps = steps,
      wghts = weights,
      FUN = function(stps, wghts) {
        # findInterval() returns the index of the last step lower than or equal
        # to each cost. negative costs (index 0) get NA, as NA costs do

        step_index <- findInterval(travel_cost, stps)
        step_index[step_index == 0L] <- NA_integer_

        weights_by_cost <- wghts[step_index]
        names(weights_by_cost) <- names(travel_cost)

        weights_by_cost
      },
      SIMPLIFY = FALSE
    )

    list_names <- mapply(
      stps = steps,
      wghts = weights,
      FUN = function(stps, wghts) {
        paste0(
          "s(", paste(stps[-1], collapse = ","), ");",
          "w(", paste(wghts[-1], collapse = ","), ")"
        )
      },
      SIMPLIFY = TRUE
    )

    names(weights_list) <- list_names

    return(weights_list)
  }

  return(weighting_function)
}


assert_steps <- function(steps) {
  is_numeric_like <- function(x) is.numeric(x) || is.integer(x)

  if (!(is_numeric_like(steps) || is.list(steps))) {
    cli::cli_abort(
      "Assertion on {.arg steps} failed: Must be either a numeric vector or a
      list of numeric vectors.",
      call = NULL
    )
  }

  if (is_numeric_like(steps)) {
    checkmate::assert_numeric(
      steps,
      lower = 1,
      finite = TRUE,
      any.missing = FALSE,
      min.len = 1,
      unique = TRUE,
      sorted = TRUE
    )
  } else {
    for (i in seq.int(length(steps))) {
      checkmate::assert_numeric(
        steps[[i]],
        lower = 1,
        finite = TRUE,
        any.missing = FALSE,
        min.len = 1,
        unique = TRUE,
        sorted = TRUE,
        .var.name = paste0("steps[[", i, "]]")
      )
    }
  }

  return(invisible(TRUE))
}


assert_weights <- function(weights, steps) {
  is_numeric_like <- function(x) is.numeric(x) || is.integer(x)

  if (is_numeric_like(steps)) {
    checkmate::assert_numeric(
      weights,
      lower = 0,
      upper = 1,
      any.missing = FALSE,
      len = length(steps)
    )
  } else {
    checkmate::assert_list(
      weights,
      types = "numeric",
      len = length(steps)
    )

    for (i in seq.int(length(weights))) {
      checkmate::assert_numeric(
        weights[[i]],
        lower = 0,
        upper = 1,
        any.missing = FALSE,
        len = length(steps[[i]]),
        .var.name = paste0("weights[[", i, "]]")
      )
    }
  }

  return(invisible(TRUE))
}
