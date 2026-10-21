apply_gravity_measure <- function(data, decay_function, travel_cost) {
  .cost_colname <- travel_cost

  # the decay function can come in two "formats"
  # - a function that returns a numeric vector
  # - a function that returns a list of numeric vectors
  # we have first to figure out which function we're dealing with, and then use
  # it accordingly

  decay_fn_output <- decay_function(1)

  is_list_length_1 <- is.list(decay_fn_output) && length(decay_fn_output) == 1
  is_numeric_like <- is.numeric(decay_fn_output) || is.integer(decay_fn_output)

  if (is_numeric_like || is_list_length_1) {
    data[, opp_weight := decay_function(get(.cost_colname))]

    access <- data
  } else {
    opp_weights <- decay_function(data[[travel_cost]])

    decay_function_args <- names(opp_weights)
    if (is.null(decay_function_args)) {
      decay_function_args <- seq_along(opp_weights)
    }
    decay_function_args <- try_to_convert_to_num(decay_function_args)

    # stacking the data once and then assigning the weights is much cheaper
    # than binding the weights to a copy of the data for each decay function
    # argument

    access <- data.table::rbindlist(rep(list(data), length(opp_weights)))
    access[, opp_weight := unlist(opp_weights, use.names = FALSE)]
    access[
      ,
      decay_function_arg := rep(decay_function_args, each = nrow(data))
    ]
    data.table::setcolorder(access, "decay_function_arg")
  }

  return(access[])
}


try_to_convert_to_num <- function(x) {
  result <- tryCatch(
    as.numeric(x),
    warning = function(cnd) cnd
  )

  if (inherits(result, "warning")) return(x)

  return(result)
}
