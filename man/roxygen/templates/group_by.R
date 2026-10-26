#' @param group_by A string referring to a column in the input data frame.
#'   Calculations are performed separately for each unique value (or
#'   combination of values) in `group_by`, and the results are stacked in the
#'   output. This is equivalent to splitting the input data by group, running
#'   the function separately for each group, and combining the results.
