#' Negative exponential decay function
#'
#' Returns a negative exponential weighting function to be used inside
#' accessibility calculating functions.
#' @template description_generic_cost
#'
#' @param decay_value A `numeric` vector. The calibration parameters that, when
#'   multiplied by the travel cost, are used as the exponent of `e` in the
#'   negative exponential function.
#'
#' @template return_decay_function
#'
#' @family decay functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' weighting_function <- decay_exponential(decay_value = 0.1)
#'
#' weighting_function(c(20, 30))
#'
#' weighting_function <- decay_exponential(decay_value = c(0.1, 0.2))
#'
#' weighting_function(c(20, 30))
#'
#' @export
decay_exponential <- function(decay_value) {
  checkmate::assert_numeric(
    decay_value,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE
  )

  weighting_function <- function(travel_cost) {
    weights_list <- weigh_unique_costs(
      travel_cost,
      function(cost) lapply(decay_value, function(x) exp(-x * cost))
    )
    names(weights_list) <- decay_value

    return(weights_list)
  }

  return(weighting_function)
}
