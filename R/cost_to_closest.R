#' Minimum travel cost to closest N number of opportunities
#'
#' Calculates the minimum travel cost to the closest N number of opportunities.
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @param n A `numeric` vector. The minimum number of opportunities that should
#'   be considered. Defaults to 1. If more than one value is provided, the
#'   output includes an extra column specifying the number of opportunities that
#'   the minimum travel cost refers to.
#' @template group_by
#' @template active
#' @param fill_missing_ids A `logical`. Calculating minimum travel cost to
#'   closest N number of opportunities may result in missing ids in the output
#'   if they cannot reach the specified amount of opportunities across all
#'   destinations they can reach. For example, estimating the minimum travel
#'   time that an origin that can only reach 4 opportunities takes to reach 5
#'   opportunities results in such origin not being included in the output.
#'   When `TRUE` (the default), the function identifies which ids would be left
#'   out from the output and fills their respective minimum travel costs with
#'   `Inf`, which incurs a performance penalty.
#'
#' @template return_accessibility
#'
#' @family accessibility measures
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' df <- cost_to_closest(
#'   travel_matrix,
#'   land_use_data,
#'   n = 1,
#'   opportunity = "schools",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' df <- cost_to_closest(
#'   travel_matrix,
#'   land_use_data,
#'   n = c(1, 2),
#'   opportunity = "schools",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' @export
cost_to_closest <- function(travel_matrix,
                            land_use_data,
                            opportunity,
                            travel_cost,
                            n = 1,
                            group_by = character(0),
                            active = TRUE,
                            fill_missing_ids = TRUE) {
  checkmate::assert_numeric(
    n,
    lower = 1,
    finite = TRUE,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE
  )
  checkmate::assert_string(opportunity)
  checkmate::assert_string(travel_cost)
  checkmate::assert_logical(active, len = 1, any.missing = FALSE)
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(
    land_use_data,
    travel_matrix,
    opportunity,
    active = active
  )

  # if not a dt, keep original class to assign later when returning result

  if (!inherits(travel_matrix, "data.table")) {
    original_class <- class(travel_matrix)
    data <- data.table::as.data.table(travel_matrix)
  } else {
    data <- data.table::copy(travel_matrix)
  }

  if (!inherits(land_use_data, "data.table")) {
    land_use_data <- data.table::as.data.table(land_use_data)
  }

  merge_by_reference(
    data,
    land_use_data,
    opportunity,
    left_df_idcol = ifelse(active, "to_id", "from_id"),
    na_as_zero = TRUE
  )

  group_id <- ifelse(active, "from_id", "to_id")
  groups <- c(group_id, group_by)
  warn_extra_cols(travel_matrix, travel_cost, group_id, groups)

  access <- calculate_cost(data, groups, opportunity, travel_cost, n)
  names(access) <- n
  access <- data.table::rbindlist(access, idcol = "n")
  access[, n := as.numeric(n)]

  if (fill_missing_ids) {
    unique_values <- lapply(groups, function(x) unique(travel_matrix[[x]]))
    unique_values <- append(unique_values, list(n))
    names(unique_values) <- c(groups, "n")

    possible_combinations <- do.call(data.table::CJ, unique_values)

    if (nrow(access) < nrow(possible_combinations)) {
      access[, min_cost := as.numeric(min_cost)]

      access <- do_fill_missing_ids(
        access,
        possible_combinations,
        groups = c(groups, "n"),
        access_col = "min_cost",
        fill_value = Inf
      )
    }
  }

  data.table::setnames(
    access,
    c(group_id, "min_cost"),
    c("id", travel_cost)
  )
  data.table::setcolorder(
    access,
    c("id", setdiff(groups, group_id), "n", travel_cost)
  )
  if (length(n) == 1) access[, n := NULL]

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}


calculate_cost <- function(data, groups, opportunity, travel_cost, n) {
  env <- environment()
  .opportunity_colname <- opportunity

  # only destinations (or origins) with opportunities are relevant. the costs
  # and opportunities get fixed names, so that min() is optimized by
  # data.table (GForce)

  data <- data[
    get(.opportunity_colname) > 0,
    c(groups, opportunity, travel_cost),
    with = FALSE
  ]
  data.table::setnames(data, c(opportunity, travel_cost), c(".opp", ".cost"))

  # n = 1 is calculated before sorting the data, to keep the order of the
  # results. for larger values of n, the data is sorted and the cumulative
  # number of opportunities is calculated only once. warnings are suppressed
  # outside of j (so min() is still optimized), because data.table evaluates
  # min() on an empty vector when no rows are selected

  if (1 %in% n) {
    cost_n1 <- suppressWarnings(
      data[, .(min_cost = min(.cost)), by = eval(groups, envir = env)]
    )
  }

  if (any(n != 1)) {
    data.table::setorderv(data, c(groups, ".cost"))
    data[, cum_opport := cumsum(.opp), by = eval(groups, envir = env)]
  }

  cost <- lapply(
    n,
    function(.x) {
      if (.x == 1) return(cost_n1)

      suppressWarnings(
        data[
          cum_opport >= .x,
          .(min_cost = min(.cost)),
          by = eval(groups, envir = env)
        ]
      )
    }
  )

  return(cost)
}
