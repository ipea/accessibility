#' Singly constrained accessibility
#'
#' Allocates opportunities at each destination proportionally based on travel
#' impedance and population at the origin. Uses the logic of Wilson's single
#' constraint. Returns values in the unit of 'demand'.
#' Internal helper function used by [constrained_accessibility()] when `constraint = "singly"`.
#'
#' @name singly_constrained
#' @keywords internal
#' @return A `data.table`/`data.frame` with results (structure mirrors the wrapper).
#' @examples NULL
#' @importFrom utils globalVariables
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
singly_constrained <- function(travel_matrix,
                               land_use_data,
                               travel_cost,
                               decay_function,
                               demand,
                               supply,
                               active,
                               group_by = character(0),
                               fill_missing_ids = TRUE,
                               detailed_results = FALSE) {
  # Validate
  checkmate::assert_string(demand)
  checkmate::assert_string(supply)
  checkmate::assert_logical(active, len = 1)

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

  # Merge demand and supply
  merge_by_reference(
    data,
    land_use_data,
    demand,
    left_df_idcol = "from_id",
    na_as_zero = TRUE
  )
  merge_by_reference(
    data,
    land_use_data,
    supply,
    left_df_idcol = "to_id",
    na_as_zero = TRUE
  )

  # Apply decay
  data <- apply_gravity_measure(data, decay_function, travel_cost)
  if ("decay_function_arg" %in% names(data)) {
    group_by <- c(group_by, "decay_function_arg")
  }

  if (active) {
    # Supply-constrained (returns units of supply).. V_ij = (O_i f(c_ij) / sum_i O_i f(c_ij)) * D_j
    data[, weighted_demand := get(demand) * opp_weight]
    data[, denom_j := sum(weighted_demand), by = c("to_id", group_by)]
    data[, kappa_singly := data.table::fifelse(denom_j > 0, weighted_demand / denom_j, 0)]
    data[, singly_access := kappa_singly * get(supply)]

    if (detailed_results) {
      access <- data[, .(
        from_id,
        to_id,
        kappa_singly,
        supply = singly_access,
        B_j = data.table::fifelse(denom_j > 0, 1 / denom_j, 0)
      )]
    } else {
      access <- data[, .(supply = sum(singly_access)), by = c("from_id", group_by)]
      if (fill_missing_ids) {
        access <- fill_missing_ids(
          access,
          travel_matrix,
          c("from_id", group_by),
          access_col = "supply"
        )
      }
    }

  } else {
    # Demand-constrained (returns units of demand).... M_ij = (D_j f(c_ij) / sum_j D_j f(c_ij)) * O_i
    data[, weighted_supply := get(supply) * opp_weight]
    data[, denom_i := sum(weighted_supply), by = c("from_id", group_by)]
    data[, hatkappa_singly := data.table::fifelse(denom_i > 0, weighted_supply / denom_i, 0)]
    data[, singly_access := hatkappa_singly * get(demand)]

    if (detailed_results) {
      access <- data[, .(
        from_id,
        to_id,
        hatkappa_singly,
        demand = singly_access,
        A_i = data.table::fifelse(denom_i > 0, 1 / denom_i, 0)
      )]
    } else {
      access <- data[, .(demand = sum(singly_access)), by = c("to_id", group_by)]
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
