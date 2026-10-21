#' @keywords internal
merge_by_reference <- function(data,
                               land_use_data,
                               opportunity,
                               left_df_idcol,
                               na_as_zero = FALSE) {
  # when calculating active accessibility, we want the number of opportunities
  # in the destination. if passive, the number of opportunities in the origin

  # matching the ids and assigning with set() is much faster than an update
  # join, which sorts the (large) travel matrix on every call. ids missing from
  # land_use_data get NA, as in a join. land_use_data ids are unique (checked
  # in the assert_*() helpers)

  left_ids <- data[[left_df_idcol]]
  right_ids <- land_use_data$id

  match_index <- if (is.character(left_ids) && is.character(right_ids)) {
    data.table::chmatch(left_ids, right_ids)
  } else {
    match(left_ids, right_ids)
  }

  values <- land_use_data[[opportunity]][match_index]

  # in accessibility measures, NA values and ids missing from land_use_data
  # count as 0 opportunities (or 0 demand/supply). the inequality and poverty
  # functions keep the NAs

  if (na_as_zero && anyNA(values)) values[is.na(values)] <- 0L

  data.table::set(data, j = opportunity, value = values)
}
