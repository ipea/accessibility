#' @keywords internal
assert_cutoff <- function(cutoff, travel_cost) {
  if (length(travel_cost) == 1) {
    checkmate::assert_numeric(
      cutoff,
      lower = 0,
      finite = TRUE,
      any.missing = FALSE,
      min.len = 1,
      unique = TRUE
    )
  } else {
    checkmate::assert_list(
      cutoff,
      any.missing = FALSE,
      len = length(travel_cost)
    )

    cutoff_collection <- checkmate::makeAssertCollection()

    for (i in seq.int(1, length(travel_cost))) {
      checkmate::assert_numeric(
        cutoff[[i]],
        lower = 0,
        finite = TRUE,
        any.missing = FALSE,
        min.len = 1,
        unique = TRUE,
        .var.name = paste0("cutoff[[", i, "]]"),
        add = cutoff_collection
      )
    }

    checkmate::reportAssertions(cutoff_collection)
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_group_by <- function(group_by) {
  checkmate::assert_character(group_by, any.missing = FALSE, unique = TRUE)

  checkmate::assert_names(group_by, disjunct.from = c("from_id", "to_id"))

  return(invisible(TRUE))
}


#' @keywords internal
assert_access_group_by <- function(group_by) {
  checkmate::assert_character(group_by, any.missing = FALSE, unique = TRUE)

  checkmate::assert_names(group_by, disjunct.from = "id")

  return(invisible(TRUE))
}


#' @keywords internal
assert_travel_matrix <- function(travel_matrix, travel_cost, group_by) {
  travel_matrix_req_names <- c("from_id", "to_id", travel_cost, group_by)
  checkmate::assert_data_frame(travel_matrix)
  checkmate::assert_names(
    names(travel_matrix),
    must.include = travel_matrix_req_names,
    .var.name = "travel_matrix"
  )

  # negative travel costs would produce weights higher than 1 in most decay
  # functions, inflating accessibility levels

  for (col in travel_cost) {
    cost_values <- travel_matrix[[col]]

    if (is.numeric(cost_values) && any(cost_values < 0, na.rm = TRUE)) {
      cli::cli_abort(
        "Assertion on {.arg travel_matrix${col}} failed: Travel costs must
        not be negative.",
        call = NULL
      )
    }
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_accessibility_data <- function(accessibility_data,
                                      opportunity,
                                      group_by) {
  required_names <- c("id", opportunity, group_by)

  checkmate::assert_data_frame(accessibility_data)
  checkmate::assert_names(
    names(accessibility_data),
    must.include = required_names,
    .var.name = "accessibility_data"
  )

  return(invisible(TRUE))
}


#' @keywords internal
assert_land_use_data <- function(land_use_data,
                                 travel_matrix,
                                 opportunity,
                                 active = NULL,
                                 demand = NULL) {
  land_use_data_req_names <- c("id", opportunity)
  if (!is.null(demand)) {
    land_use_data_req_names <- c(land_use_data_req_names, demand)
  }

  checkmate::assert_data_frame(land_use_data)
  checkmate::assert_names(
    names(land_use_data),
    must.include = land_use_data_req_names,
    .var.name = "land_use_data"
  )

  # duplicated ids would be silently resolved by the joins with the travel
  # matrix / accessibility data (only one of the rows would be used)

  if (anyDuplicated(land_use_data$id)) {
    duplicated_ids <- unique(land_use_data$id[duplicated(land_use_data$id)])

    cli::cli_abort(
      "{.arg land_use_data} must not contain duplicated ids. Found
      duplicates: {.val {duplicated_ids}}.",
      call = NULL
    )
  }

  # if an id is present in travel_matrix but not in land_use_data, merging the
  # datasets will produce NAs, so we warn users about that

  travel_matrix_ids <- if (is.null(active)) {
    c(travel_matrix$from_id, travel_matrix$to_id)
  } else if (active) {
    travel_matrix$to_id
  } else {
    travel_matrix$from_id
  }

  # joining numeric ids to character/factor ids fails with an obscure
  # data.table error, so we check the id types before warning about missing ids

  is_text_like <- function(x) is.character(x) || is.factor(x)

  if (is_text_like(travel_matrix_ids) != is_text_like(land_use_data$id)) {
    cli::cli_abort(
      "The id columns of {.arg travel_matrix} ({.field from_id}/{.field to_id})
      and {.arg land_use_data} ({.field id}) must be of compatible types.
      Found {.cls {class(travel_matrix_ids)[1]}} in {.arg travel_matrix} and
      {.cls {class(land_use_data$id)[1]}} in {.arg land_use_data}.",
      call = NULL
    )
  }

  if (!all(travel_matrix_ids %in% land_use_data$id)) {
    cli::cli_warn(
      "{.arg land_use_data} is missing ids listed in {.arg travel_matrix},
      which may produce NAs in the final output."
    )
  }

  # if either land_use_data$opportunity or $demand contains NA values, the final
  # result may contain NAs as well, so we warn about that too

  cols_to_check <- c(
    opportunity,
    if (is.null(demand)) character(0) else demand
  )

  for (col in cols_to_check) {
    if (any(is.na(land_use_data[[col]]))) {
      cli::cli_warn(
        "{.arg land_use_data${col}} contains NA values, which may produce NAs
        in the final output."
      )
    }
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_sociodemographic_data <- function(sociodemographic_data,
                                         accessibility_data,
                                         population = NULL,
                                         income = NULL,
                                         extra_cols = NULL) {
  population <- if (is.null(population)) character() else population
  income <- if (is.null(income)) character() else income
  extra_cols <- if (is.null(extra_cols)) character() else extra_cols
  required_names <- c("id", population, income, extra_cols)

  checkmate::assert_data_frame(sociodemographic_data)
  checkmate::assert_names(
    names(sociodemographic_data),
    must.include = required_names,
    .var.name = "sociodemographic_data"
  )

  # duplicated ids would be silently resolved by the joins with the travel
  # matrix / accessibility data (only one of the rows would be used)

  if (anyDuplicated(sociodemographic_data$id)) {
    ids <- sociodemographic_data$id
    duplicated_ids <- unique(ids[duplicated(ids)])

    cli::cli_abort(
      "{.arg sociodemographic_data} must not contain duplicated ids. Found
      duplicates: {.val {duplicated_ids}}.",
      call = NULL
    )
  }

  # if an id is present in accessibility_data but not in sociodemographic_data,
  # merging the datasets will produce NAs, so we warn users about that

  if (!all(accessibility_data$id %in% sociodemographic_data$id)) {
    cli::cli_warn(
      "{.arg sociodemographic_data} is missing ids listed in
      {.arg accessibility_data}, which may produce NAs in the final output."
    )
  }

  # if any of the columns in sociodemographic_data required to calculate
  # inequality contains NA values, the final result may contain NAs as well, so
  # we warn about that too
  # if NAs are found in income column, we check if the correspondent population
  # entries are 0. if not, we throw the warning, otherwise we ignore it. related
  # to https://github.com/ipea/accessibility/issues/42

  non_income_cols <- c(population, extra_cols)

  for (col in non_income_cols) {
    if (any(is.na(sociodemographic_data[[col]]))) {
      cli::cli_warn(
        "{.arg sociodemographic_data${col}} contains NA values, which may
        produce NAs in the final output."
      )
    }
  }

  if (!identical(income, character())) {
    if (any(is.na(sociodemographic_data[[income]]))) {
      .inc_col <- income
      na_entries <- sociodemographic_data[
        is.na(sociodemographic_data[[.inc_col]]),
      ]
      pop_na_entries <- na_entries[[population]]

      should_warn <- any(pop_na_entries > 0)
      should_warn <- ifelse(is.na(should_warn), TRUE, should_warn)

      if (should_warn) {
        cli::cli_warn(
          "{.arg sociodemographic_data${income}} contains NA values whose
          correspodent {.arg sociodemographic_data$population} is not 0,
          which may produce NAs in the final output."
        )
      }
    }
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_summary_function <- function(summary_function) {
  checkmate::assert_function(summary_function)

  result <- tryCatch(
    summary_function(1:100),
    error = function(cnd) cnd
  )

  if (inherits(result, "error")) {
    cli::cli_abort(
      "Assertion on {.arg summary_function} failed: Must be a function that
      takes a numeric vector as input. Instead, failed with message:
      {.val {conditionMessage(result)}}",
      call = NULL
    )
  }

  if (!is.numeric(result) || length(result) != 1) {
    cli::cli_abort(
      "Assertion on {.arg summary_function} failed: Must be a function that
      takes a numeric vector as input and returns a single numeric as output.
      Instead, returned: {.val {result}}",
      call = NULL
    )
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_decay_function <- function(decay_function) {
  checkmate::assert_function(decay_function)

  result <- tryCatch(
    decay_function(1:100),
    error = function(cnd) cnd
  )

  if (inherits(result, "error")) {
    cli::cli_abort(
      "Assertion on {.arg decay_function} failed: Must be a function that
      takes a numeric vector as input. Instead, failed with message:
      {.val {conditionMessage(result)}}",
      call = NULL
    )
  }

  # result must be either a numeric vector with same length as input or a list
  # of numeric vectors whose lenghts are the same as input

  is_numeric_like <- function(x) is.numeric(x) || is.integer(x)

  right_numeric <- is_numeric_like(result) && length(result) == 100

  numeric_like_elements <- vapply(result, is_numeric_like, logical(1))
  right_classes <- length(result) > 0 && all(numeric_like_elements)

  elements_length <- vapply(result, length, integer(1))
  right_lengths <- length(result) > 0 && all(elements_length == 100)

  if (!(right_numeric || (is.list(result) && right_classes && right_lengths))) {
    cli::cli_abort(
      c(
        "Assertion on {.arg decay_function} failed: Must be a function that
        takes a numeric vector as input and returns either:",
        "*" = "a numeric vector with the same length of input, or;",
        "*" = "a list of numeric vectors whose lengths are the same of input.",
        "i" = "Instead, with input {.code 1:100} it returned: {.val {result}}"
      ),
      call = NULL
    )
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_interval_increment <- function(interval_increment) {
  checkmate::assert_number(interval_increment, finite = TRUE)

  if (interval_increment <= 0) {
    cli::cli_abort(
      "Assertion on {.arg interval_increment} failed: Value must be greater
      than 0.",
      call = NULL
    )
  }

  return(invisible(TRUE))
}


#' @keywords internal
assert_and_assign_interval <- function(interval) {
  is_numeric_like <- function(x) is.numeric(x) || is.integer(x)

  build_interval_name <- function(pair) {
    paste0("[", pair[1], ",", pair[2], "]")
  }

  if (is.list(interval)) {
    checkmate::assert_list(
      interval,
      types = "numeric",
      any.missing = FALSE,
      min.len = 1,
      unique = TRUE
    )

    for (i in seq.int(length(interval))) {
      checkmate::assert_numeric(
        interval[[i]],
        lower = 0,
        any.missing = FALSE,
        len = 2,
        unique = TRUE,
        sorted = TRUE,
        finite = TRUE,
        .var.name = paste0("interval[[", i, "]]")
      )
    }

    names(interval) <- vapply(interval, build_interval_name, character(1))
  } else if (is_numeric_like(interval)) {
    checkmate::assert_numeric(
      interval,
      lower = 0,
      any.missing = FALSE,
      len = 2,
      unique = TRUE,
      sorted = TRUE,
      finite = TRUE
    )

    interval <- list(interval)
    names(interval) <- build_interval_name(interval[[1]])
  } else {
    cli::cli_abort(
      c(
        "Assertion on {.arg interval} failed: Must be either:",
        "*" = "a numeric vector with 2 elements, indicating the start and end
        points of the travel cost interval;",
        "*" = "a list of numeric vectors with 2 elements, each one of them
        indicating the start and end points of a travel cost interval."
      ),
      call = NULL
    )
  }

  return(interval)
}


#' @keywords internal
assert_detailed_fill_missing_ids <- function(fill_missing_ids,
                                             detailed_results) {
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)

  if (detailed_results && !fill_missing_ids) {
    cli::cli_warn(
      "Found non-default {.arg fill_missing_ids} (FALSE) with
      {.code detailed_results = TRUE}. Please note that
      {.arg fill_missing_ids} does not affect the detailed output."
    )
  }

  return(invisible(TRUE))
}
