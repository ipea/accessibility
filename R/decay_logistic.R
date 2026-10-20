#' Logistic decay function
#'
#' Returns a logistic weighting function (in which the weights
#' follow the distribution of a reversed cumulative logistic curve) to be
#' used inside accessibility calculating functions. The logistic curve is
#' parameterized with the cutoff that sets its inflection point and the standard
#' deviation that sets its steepness.
#' @template description_generic_cost
#'
#' @param cutoff A `numeric` vector. The cost value that serves as the
#'   inflection point of the cumulative logistic curve.
#' @param sd A `numeric` vector with same length as `cutoff`. The standard
#'   deviation of the logistic curve. Values near 0 result in weighting curves
#'   that approximate binary decay, while higher values tend to linearize the
#'   decay.
#'
#' @return A `function` that takes a generic travel cost vector (`numeric`) as
#'   input and returns a vector of weights (`numeric`).
#'
#' @details When using a function created with `decay_logistic()`, the output is
#'   named after the combination of cutoffs (`"c"`) and standard deviations
#'   (`"sd"`) - e.g. given the cutoffs `c(30, 40)` and the standard deviations
#'   `c(10, 20)`, the first element of the output will be named `"c30;sd10"` and
#'   the second will be named `"c40;sd20"`. This function uses the adjusted
#'   logistic decay curve proposed by
#'   \insertCite{bauer2016measuring;textual}{accessibility}, in which the
#'   condition f(0) = 1 is met (i.e. the weight of an opportunity whose cost to
#'   reach is 0 is 1).
#'
#' @references \insertAllCited{}
#'
#' @family decay functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' weighting_function <- decay_logistic(cutoff = 30, sd = 5)
#'
#' weighting_function(c(0, 30, 45, 60))
#'
#' weighting_function <- decay_logistic(cutoff = c(30, 45), sd = c(5, 10))
#'
#' weighting_function(c(0, 30, 45, 60))
#'
#' @export
decay_logistic <- function(cutoff, sd) {
  assert_logistic_cutoff(cutoff)
  assert_standard_deviation(sd, cutoff)

  # duplicated (cutoff, sd) pairs would produce duplicated list names, which
  # are merged/double counted downstream

  if (anyDuplicated(data.frame(cutoff, sd))) {
    stop(
      "Assertion on 'cutoff' and 'sd' failed: ",
      "Must not contain duplicated (cutoff, sd) pairs.",
      call. = FALSE
    )
  }

  weighting_function <- function(travel_cost) {
    g <- function(cost, median, std_dev) {
      1 + exp(((cost - median) * base::pi) / (std_dev * sqrt(3)))
    }

    sd_list <- mapply(
      median = cutoff,
      std_dev = sd,
      FUN = function(median, std_dev) {
        vapply(
          travel_cost,
          function(x) g(0, median, std_dev) / g(x, median, std_dev),
          numeric(1)
        )
      },
      SIMPLIFY = FALSE
    )

    list_names <- paste0("c", cutoff, ";sd", sd)
    names(sd_list) <- list_names

    return(sd_list)
  }

  return(weighting_function)
}

assert_logistic_cutoff <- function(cutoff) {
  checkmate::assert(
    checkmate::check_numeric(
      cutoff,
      finite = TRUE,
      any.missing = FALSE,
      min.len = 1
    ),
    check_higher_than_zero(cutoff),
    combine = "and"
  )
}

assert_standard_deviation <- function(sd, cutoff) {
  checkmate::assert(
    checkmate::check_numeric(
      sd,
      finite = TRUE,
      any.missing = FALSE,
      len = length(cutoff)
    ),
    check_higher_than_zero(sd),
    combine = "and"
  )
}

check_higher_than_zero <- function(x) {
  if (any(x <= 0)) return("Must be higher than 0")

  return(TRUE)
}
