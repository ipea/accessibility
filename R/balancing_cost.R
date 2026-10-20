#' Balancing cost accessibility measure
#'
#' Calculates the balancing cost measure, which is defined as the travel cost
#' required to reach as many opportunities as the number of people in a given
#' origin. Originally proposed by
#'  \insertCite{barboza2021balancing;textual}{accessibility}, under the name
#' "balancing time".
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @template demand
#' @param cost_increment A number. The cost increment that should be used when
#'   defining the travel cost distribution from which the potential balancing
#'   costs will be picked. For example, an increment of 1 tends to be suitable for
#'   travel time distributions, meaning that the function will first check if
#'   any origins reach their balancing cost with a travel time of 0 minutes,
#'   then 1 minute, 2 minutes, 3, 4, ..., etc. An increment of 1 might be too big
#'   for a distribution of monetary costs, on the other hand, which could
#'   possibly benefit from a smaller increment of 0.05, for example, resulting
#'   in the function looking for balancing costs first at a cost of 0, then
#'   0.05, 0.10, ..., etc. Defaults to 1.
#' @template group_by
#' @param fill_missing_ids A `logical`. Origins that never reach as many
#'   opportunities as there are people residing in them, as well as (when
#'   `group_by` is not empty) combinations of groups and origins missing from
#'   the travel matrix, would not be included in the output. When `TRUE` (the
#'   default), the function identifies which combinations would be left out and
#'   fills their respective balancing costs with `NA`, which incurs a
#'   performance penalty.
#'
#' @return A data frame containing the balancing cost of each origin in the
#'   travel matrix. Origins with a `NA` balancing cost never reach as many
#'   opportunities as there are people residing in them, given the specified
#'   travel matrix.
#'
#' @references
#' \insertAllCited{}
#'
#' @family accessibility measures
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' bc <- balancing_cost(
#'   travel_matrix,
#'   land_use_data,
#'   opportunity = "jobs",
#'   travel_cost = "travel_time",
#'   demand = "population"
#' )
#' head(bc)
#' @export
balancing_cost <- function(travel_matrix,
                           land_use_data,
                           opportunity,
                           travel_cost,
                           demand,
                           cost_increment = 1,
                           group_by = character(0),
                           fill_missing_ids = TRUE) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(travel_cost)
  checkmate::assert_string(demand)
  checkmate::assert_number(cost_increment, finite = TRUE)
  if (cost_increment <= 0) {
    cli::cli_abort(
      "Assertion on {.arg cost_increment} failed: Value must be greater
      than 0.",
      call = NULL
    )
  }
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(
    land_use_data,
    travel_matrix,
    opportunity,
    demand = demand
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

  merge_by_reference(data, land_use_data, opportunity, left_df_idcol = "to_id")

  groups <- c("from_id", group_by)
  warn_extra_cols(travel_matrix, travel_cost, "from_id", groups)

  lookup_vec <- land_use_data[[demand]]
  names(lookup_vec) <- land_use_data$id

  max_lookup_cost <- if (length(data[[travel_cost]]) > 0) {
    max(data[[travel_cost]], na.rm = TRUE)
  } else {
    0
  }

  # the last cost must be at least the max cost, otherwise origins that only
  # balance after the last multiple of cost_increment are reported as NA

  lookup_costs <- seq.int(
    0,
    ceiling(max_lookup_cost / cost_increment) * cost_increment,
    by = cost_increment
  )

  # origins with 0 people should always have a balancing time of 0

  .demand_colname <- demand
  no_pop_origins <- land_use_data[get(.demand_colname) == 0]$id
  no_pop_origins_in_ttm <- no_pop_origins[no_pop_origins %in% data$from_id]

  grouped_no_pop_origins <- lapply(
    groups,
    function(group) {
      if (group == "from_id") return(no_pop_origins_in_ttm)
      unique(data[[group]])
    }
  )
  names(grouped_no_pop_origins) <- groups

  access <- do.call(data.table::CJ, grouped_no_pop_origins)
  access[, cost := 0]

  data <- data[!(from_id %in% no_pop_origins_in_ttm)]

  for (i in lookup_costs) {
    cum_opps <- calc_cum_cutoff(data, groups, opportunity, travel_cost, i)

    cum_opps[, did_balance := access >= lookup_vec[as.character(from_id)]]
    balanced <- cum_opps[did_balance == TRUE]

    if (nrow(balanced) > 0) {
      balanced[, c("access", "did_balance") := NULL]
      balanced[, cost := i]

      access <- rbind(access, balanced)

      data <- data[!balanced, on = groups]

      if (nrow(data) == 0) break
    }
  }

  if (fill_missing_ids) {
    unique_values <- lapply(groups, function(x) unique(travel_matrix[[x]]))
    names(unique_values) <- groups

    possible_combinations <- do.call(data.table::CJ, unique_values)

    if (nrow(access) < nrow(possible_combinations)) {
      access <- do_fill_missing_ids(
        access,
        possible_combinations,
        groups = groups,
        access_col = "cost",
        fill_value = NA
      )
    }
  }

  data.table::setnames(access, c("from_id", "cost"), c("id", travel_cost))
  data.table::setcolorder(
    access,
    c("id", setdiff(groups, "from_id"), travel_cost)
  )
  data.table::setorderv(access, c("id", setdiff(groups, "from_id")))

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}


calc_cum_cutoff <- function(data, groups, opportunity, travel_cost, .cutoff) {
  env <- environment()
  .opportunity_colname <- opportunity
  .cost_colname <- travel_cost

  data <- data[get(.cost_colname) <= .cutoff]

  cum_cutoff_access <- data[
    ,
    .(access = sum(get(.opportunity_colname))),
    by = eval(groups, envir = env)
  ]

  return(cum_cutoff_access)
}
