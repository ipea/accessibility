#' @param land_use_data A data frame. The distribution of opportunities within
#'   the study area cells. Must contain the columns `id` and any others
#'   specified in `opportunity`. `NA` values, and ids in `travel_matrix` that
#'   are missing from this table, are treated as 0.
