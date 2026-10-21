#' Inverse power decay function
#'
#' Returns an inverse power weighting function to be used inside accessibility
#' calculating functions.
#' @template description_generic_cost
#'
#' @param decay_value A `numeric` vector. The calibration parameters to be used
#'   as the exponents in the inverse power function.
#'
#' @template return_decay_function
#'
#' @family decay functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' weighting_function <- decay_power(decay_value = 0.1)
#'
#' weighting_function(c(20, 35))
#'
#' weighting_function <- decay_power(decay_value = c(0.1, 0.2))
#'
#' weighting_function(c(20, 35))
#'
#' @export
decay_power <- function(decay_value) {
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
      function(cost) {
        lapply(
          decay_value,
          function(x) {
            weights <- cost ^ (-x)
            weights[weights > 1] <- 1
            weights
          }
        )
      }
    )
    names(weights_list) <- decay_value

    return(weights_list)
  }

  return(weighting_function)
}
