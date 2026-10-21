#' @param decay_function A `function` that converts travel cost into an
#'   impedance factor used to weight opportunities. This function should take a
#'   `numeric` vector and also return a `numeric` vector as output, with the
#'   same length as the input. For convenience, the package currently includes
#'   the following functions: [decay_binary()], [decay_exponential()],
#'   [decay_linear()], [decay_logistic()], [decay_power()] and
#'   [decay_stepped()]. See the documentation of each decay function for more
#'   details.

