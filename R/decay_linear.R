#' Linear decay function
#'
#' Returns a linear weighting function to be used inside accessibility
#' calculating functions.
#' @template description_generic_cost
#'
#' @param cutoff A `numeric` vector. Indicates the travel cost cutoffs until
#'   which the weighting factor decays linearly. From this point onward the
#'   weight is equal to 0. Must be greater than 0.
#'
#' @template return_decay_function
#'
#' @family decay functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' weighting_function <- decay_linear(cutoff = 30)
#'
#' weighting_function(c(20, 35))
#'
#' weighting_function <- decay_linear(cutoff = c(30, 45))
#'
#' weighting_function(c(20, 35))
#'
#' @export
decay_linear <- function(cutoff) {
  checkmate::assert_numeric(
    cutoff,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE
  )

  # a cutoff of 0 would produce NaN weights when travel cost is 0 (0 / 0)

  if (any(cutoff <= 0)) {
    stop(
      "Assertion on 'cutoff' failed: Value must be greater than 0.",
      call. = FALSE
    )
  }

  weighting_function <- function(travel_cost) {
    weights_list <- lapply(
      cutoff,
      function(x) {
        weights <- 1 - travel_cost / x
        weights[weights < 0] <- 0
        weights
      }
    )
    names(weights_list) <- cutoff

    return(weights_list)
  }

  return(weighting_function)
}
