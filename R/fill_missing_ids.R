fill_missing_ids <- function(access_df,
                             travel_matrix,
                             groups,
                             access_col = "access") {
  unique_values <- lapply(groups, function(x) unique(travel_matrix[[x]]))
  names(unique_values) <- groups

  if ("decay_function_arg" %in% groups) {
    unique_values$decay_function_arg <- unique(access_df$decay_function_arg)
  }
  possible_combinations <- do.call(data.table::CJ, unique_values)

  if (nrow(access_df) < nrow(possible_combinations)) {
    access_df <- do_fill_missing_ids(
      access_df,
      possible_combinations,
      groups,
      access_col = access_col
    )
  }

  return(access_df)
}


do_fill_missing_ids <- function(access_df,
                                possible_combinations,
                                groups,
                                access_col = "access",
                                fill_value = 0) {
  filled_access_df <- merge(
    possible_combinations,
    access_df,
    by = groups,
    all.x = TRUE
  )

  filled_access_df[
    is.na(get(access_col)),
    eval(access_col, envir = parent.frame()) := fill_value
  ]

  return(filled_access_df[])
}
