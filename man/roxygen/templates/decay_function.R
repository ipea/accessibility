#' @param decay_function A `function` that converts travel cost into an
#'   impedance factor used to weight opportunities. This function should take a
#'   `numeric` vector and also return a `numeric` vector as output, with the
#'   same length as the input. For convenience, the package currently includes
#'   the following functions: [decay_binary()], [decay_exponential()],
#'   [decay_linear()], [decay_logistic()], [decay_power()] and
#'   [decay_stepped()]. See the documentation of each decay function for more
#'   details.
#'
#'   When a decay function is specified with multiple parameter values (e.g.
#'   `decay_exponential(c(0.1, 0.5))`), calculations are performed separately
#'   for each parameter value and the results are stacked in the output. This
#'   is equivalent to running the function separately for each parameter value
#'   and combining the results. A `decay_function_arg` column identifies the
#'   parameter value associated with each result.
