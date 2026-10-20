#' @keywords internal
warn_extra_cols <- function(travel_matrix, travel_cost, group_id, groups) {
  travel_matrix_extra_cols <- setdiff(names(travel_matrix), groups)
  travel_matrix_extra_cols <- setdiff(travel_matrix_extra_cols, travel_cost)
  if (group_id == "from_id") {
    travel_matrix_extra_cols <- setdiff(travel_matrix_extra_cols, "to_id")
  } else {
    travel_matrix_extra_cols <- setdiff(travel_matrix_extra_cols, "from_id")
  }

  if (!identical(travel_matrix_extra_cols, character(0))) {
    cli::cli_warn(
      c(
        "Found columns in {.arg travel_matrix} not listed in either
        {.arg travel_cost} or {.arg group_by}:
        {.val {travel_matrix_extra_cols}}.",
        "i" = "This can result in excessive aggregation when calculating
        accessibility, if these columns serve as group ids in
        {.arg travel_matrix}."
      )
    )
  }

  invisible(TRUE)
}

#' @keywords internal
warn_extra_access_cols <- function(accessibility_data, opportunity, group_id) {
  extra_cols <- setdiff(
    names(accessibility_data),
    c("id", opportunity, group_id)
  )

  if (!identical(extra_cols, character(0))) {
    cli::cli_warn(
      c(
        "Found columns in {.arg accessibility_data} not listed in either
        {.arg opportunity} or {.arg group_by}: {.val {extra_cols}}.",
        "i" = "This can result in excessive aggregation when calculating
        inequality measures, if these columns serve as group ids in
        {.arg accessibility_data}."
      )
    )
  }

  invisible(TRUE)
}
