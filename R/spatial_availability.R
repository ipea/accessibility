#' Spatial availability
#'
#' Calculates spatial availability, an accessibility measure proposed by
#' \insertCite{soukhov2023introducing;textual}{accessibility} that takes into
#' account competition effects. The accessibility levels that result from using
#' this measure are proportional both to the demand in each origin and to the
#' travel cost it takes to reach the destinations. The spatial availability is
#' a particular case of `constrained_accessibility(constraint = "singly")`.
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @template demand
#' @template decay_function
#' @param alpha A `numeric`. A parameter used to modulate the effect of demand
#'   by population. When less than 1, opportunities are allocated more rapidly
#'   to smaller centers relative to larger ones; values higher than 1 achieve
#'   the opposite effect.
#' @template group_by
#' @template fill_missing_ids_combinations
#' @param detailed_results A `logical`. Whether to return spatial availability
#'   results aggregated by origin-destination pair (`TRUE`) or by origin
#'   (`FALSE`, the default). When `TRUE`, the output also includes the demand,
#'   impedance and combined balancing factors used to calculate spatial
#'   availability. Please note that the argument `fill_missing_ids`
#'   does not affect the output when `detailed_results` is `TRUE`.
#'
#' @return A data frame containing the spatial availability estimates for
#'   each origin in the travel matrix. When `detailed_results` is `TRUE`, the
#'   estimates are given for each origin-destination pair instead, alongside the
#'   balancing factors used to calculate them.
#'
#' @references
#' \insertAllCited{}
#'
#' @family Constrained accessibility
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' # the example below is based on Soukhov et al. (2023) paper
#'
#' travel_matrix <- data.table::data.table(
#'   from_id = rep(c("A", "B", "C"), each = 3),
#'   to_id = as.character(rep(1:3, 3)),
#'   travel_time = c(15, 30, 100, 30, 15, 100, 100, 100, 15)
#' )
#' land_use_data <- data.table::data.table(
#'   id = c("A", "B", "C", "1", "2", "3"),
#'   population = c(50000, 150000, 10000, 0, 0, 0),
#'   jobs = c(0, 0, 0, 100000, 100000, 10000)
#' )
#'
#' df <- spatial_availability(
#'   travel_matrix,
#'   land_use_data,
#'   opportunity = "jobs",
#'   travel_cost = "travel_time",
#'   demand = "population",
#'   decay_function = decay_exponential(decay_value = 0.1)
#' )
#' df
#'
#' detailed_df <- spatial_availability(
#'   travel_matrix,
#'   land_use_data,
#'   opportunity = "jobs",
#'   travel_cost = "travel_time",
#'   demand = "population",
#'   decay_function = decay_exponential(decay_value = 0.1),
#'   detailed_results = TRUE
#' )
#' detailed_df
#'
#' @export
spatial_availability <- function(travel_matrix,
                                 land_use_data,
                                 opportunity,
                                 travel_cost,
                                 demand,
                                 decay_function,
                                 alpha = 1,
                                 group_by = character(0),
                                 fill_missing_ids = TRUE,
                                 detailed_results = FALSE) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(travel_cost)
  checkmate::assert_string(demand)
  checkmate::assert_number(alpha, lower = 0, finite = TRUE)
  checkmate::assert_logical(detailed_results, len = 1, any.missing = FALSE)
  assert_decay_function(decay_function)
  assert_group_by(group_by)
  assert_detailed_fill_missing_ids(fill_missing_ids, detailed_results)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(
    land_use_data,
    travel_matrix,
    opportunity,
    demand = demand
  )

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
  merge_by_reference(data, land_use_data, demand, left_df_idcol = "from_id")

  data <- apply_gravity_measure(data, decay_function, travel_cost)

  groups <- c("from_id", group_by)
  if ("decay_function_arg" %in% names(data)) {
    groups <- c(groups, "decay_function_arg")
    group_by <- c(group_by, "decay_function_arg")
  }

  warn_extra_cols(
    travel_matrix,
    travel_cost,
    group_id = "from_id",
    groups = groups
  )

  .demand_colname <- demand

  # na.rm because ids that are not in travel_matrix may have NA demand. this
  # sum cancels out in combined_bal_fac anyway

  total_demand <- sum(land_use_data[[.demand_colname]] ^ alpha, na.rm = TRUE)
  data[, demand_bal_fac := (get(.demand_colname) ^ alpha) / total_demand]

  # destinations that no one reaches (or that are only reached by origins
  # without demand) have null denominators. their opportunities are not
  # allocated to any origin, so their factors are set to 0 instead of NaN

  data[
    ,
    impedance_bal_fac := {
      denominator <- sum(opp_weight)
      if (isTRUE(denominator == 0)) 0 else opp_weight / denominator
    },
    by = c("to_id", group_by)
  ]

  data[
    ,
    combined_bal_fac := {
      numerator <- demand_bal_fac * impedance_bal_fac
      denominator <- sum(numerator)
      if (isTRUE(denominator == 0)) 0 else numerator / denominator
    },
    by = c("to_id", group_by)
  ]

  .opportunity_colname <- opportunity
  data[
    ,
    spatial_availability := combined_bal_fac * get(.opportunity_colname),
    by = c("to_id", group_by)
  ]

  if (detailed_results) {
    cols_to_drop <- c(travel_cost, opportunity, demand, "opp_weight")
    access <- data[, (cols_to_drop) := NULL]

    data.table::setnames(access, "spatial_availability", opportunity)
  } else {
    access <- data[
      ,
      .(access = sum(spatial_availability)),
      by = c("from_id", group_by)
    ]

    if (fill_missing_ids) {
      access <- fill_missing_ids(access, travel_matrix, groups)
    }

    data.table::setnames(access, c("from_id", "access"), c("id", opportunity))
  }

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}
