#' Total constrained accessibility
#'
#' Allocates total opportunities in the region proportionally based on travel
#' impedance. Uses the logic of a total (or unconstrained by Wilson's terms)
#' constraint. Returns values in units of 'supply' (i.e., opportunities) if
#' `active = TRUE` and returns values in units of demand' (i.e., population)
#' if `active = FALSE`.
#'
#' Internal helper used by [constrained_accessibility()] when `constraint = "total"`.
#'
#' @name total_constrained
#' @keywords internal
#' @return A `data.table`/`data.frame` with results (structure mirrors the wrapper).
#' @examples NULL
#'
#' @importFrom utils globalVariables
#'
utils::globalVariables(c(
  # common ids / columns
  "from_id", "to_id", "id", "opp_weight", "supply", "demand", "weighted_demand", "weighted_supply",
  # total-constrained
  "kappa_total", "hatkappa_total", "K_total", "hatK_total", "constrained_opportunity",
  # singly-constrained
  "denom_i", "denom_j", "kappa_singly", "hatkappa_singly", "A_i", "B_j", "singly_access",
  # doubly-constrained
  "kappa_doubly", "flow", "error"
))
total_constrained <- function(travel_matrix,
                              land_use_data,
                              travel_cost,
                              decay_function,
                              group_by = character(0),
                              fill_missing_ids = TRUE,
                              detailed_results = FALSE,
                              active,
                              demand = NULL,   # population
                              supply = NULL) { # jobs

  # Validate inputs
  checkmate::assert_string(travel_cost)
  checkmate::assert_logical(detailed_results, len = 1, any.missing = FALSE)
  checkmate::assert_logical(active, len = 1, any.missing = FALSE)

  if (active) {
    #active accessibility
    if (is.null(supply) || !is.null(demand)) {
      cli::cli_abort(
        "For {.code active = TRUE}, {.arg supply} must be specified and
        {.arg demand} must be NULL.",
        call = NULL
      )
    }
    merge_id <- "to_id"
    group_id <- "from_id"
    weighted_col <- "weighted_supply"
    kappa_col <- "kappa_total"
    total_col <- "K_total"
    result_col <- "supply"
    opportunity_col <- supply
  } else {
    #passive accessibility
    if (is.null(demand) || !is.null(supply)) {
      cli::cli_abort(
        "For {.code active = FALSE}, {.arg demand} must be specified and
        {.arg supply} must be NULL.",
        call = NULL
      )
    }
    merge_id <- "from_id"
    group_id <- "to_id"
    weighted_col <- "weighted_demand"
    kappa_col <- "hatkappa_total"
    total_col <- "hatK_total"
    result_col <- "demand"
    opportunity_col <- demand
  }

  assert_decay_function(decay_function)
  assert_group_by(group_by)
  assert_detailed_fill_missing_ids(fill_missing_ids, detailed_results)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(land_use_data, travel_matrix, opportunity_col)

  # Convert to data.table
  if (!inherits(travel_matrix, "data.table")) {
    original_class <- class(travel_matrix)
    data <- data.table::as.data.table(travel_matrix)
  } else {
    data <- data.table::copy(travel_matrix)
  }
  if (!inherits(land_use_data, "data.table")) {
    land_use_data <- data.table::as.data.table(land_use_data)
  }

  # Merge land use data
  merge_by_reference(
    data,
    land_use_data,
    opportunity_col,
    left_df_idcol = merge_id,
    na_as_zero = TRUE
  )

  # Apply decay
  data <- apply_gravity_measure(data, decay_function, travel_cost)

  # Core calculation
  data[, (weighted_col) := get(opportunity_col) * opp_weight]
  total_weighted_system <- data[, sum(get(weighted_col))]
  data[, (kappa_col) := get(weighted_col) / total_weighted_system]

  ids_for_total <- unique(data[[merge_id]])                   # e.g., A,B,C when active=TRUE
  total_opportunities_region <- sum(
    land_use_data[[opportunity_col]][match(ids_for_total, land_use_data$id)],
    na.rm = TRUE
  )

  data[, constrained_opportunity := get(kappa_col) * total_opportunities_region]

  if (detailed_results) {
    if (!active) {
      access <- data[, .(
        from_id,
        to_id,
        weighted_demand,
        hatkappa_total,
        demand = constrained_opportunity,
        hatK_total = total_opportunities_region / total_weighted_system
      )]
    } else {
      # supply-side details (active accessibility)
      access <- data[, .(
        from_id,
        to_id,
        weighted_supply,
        kappa_total,
        supply = constrained_opportunity,
        K_total = total_opportunities_region / total_weighted_system
      )]
    }
  } else {
    if (active) {
      # supply aggregated by origin (from_id)
      access <- data[, .(supply = sum(constrained_opportunity)), by = c("from_id", group_by)]
      if (fill_missing_ids) {
        access <- fill_missing_ids(
          access,
          travel_matrix,
          c("from_id", group_by),
          access_col = "supply"
        )
      }
    } else {
      # demand aggregated by destination (to_id)
      access <- data[, .(demand = sum(constrained_opportunity)), by = c("to_id", group_by)]
      if (fill_missing_ids) {
        access <- fill_missing_ids(
          access,
          travel_matrix,
          c("to_id", group_by),
          access_col = "demand"
        )
      }
    }
  }

  if (exists("original_class")) class(access) <- original_class
  return(access[])
}
