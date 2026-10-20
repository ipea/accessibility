#' Constrained accessibility
#'
#' Calculates accessibility using constraints, as proposed in
#' \insertCite{soukhov2025family;textual}{accessibility}. Accessibility is
#' conceptualised as potential spatial interaction. This function covers three
#' constraint cases. Please see the Details section for more information.
#'
#' @template travel_matrix
#' @template land_use_data
#' @template travel_cost
#' @template demand
#' @template supply
#' @param constraint A string. One of `"total"`, `"singly"`, or `"doubly"`. See
#'        Details section for more information.
#' @template decay_function
#' @param active A logical. When `TRUE`, the function calculates active
#'        accessibility (the quantity of opportunities that can be reached from
#'        a given origin). When `FALSE`, it calculates passive accessibility (by
#'        how many people each destination can be reached), which is equivalent
#'        to the notion of market potential. This parameter only works for
#'        `constraint` types `"total"` and `"singly"`. Ignored for
#'        `constraint = "doubly"`.
#' @param error_threshold Numeric. Convergence criterion used only for
#' calibration in the doubly-constrained case (`constraint = "doubly"`).
#' @param improvement_threshold Numeric. Convergence criterion for improvement
#' used only for calibration in the doubly-constrained case
#' (`constraint = "doubly"`).
#' @param max_iterations Integer. Maximum iterations used only for calibration
#' in the doubly-constrained case (`constraint = "doubly"`).
#' @template group_by
#' @template fill_missing_ids_combinations
#' @param detailed_results Logical. Whether to return detailed OD-level results.
#'
#'
#' @section Details:
#' This function covers the family of constrained accessibility measures
#' proposed in \insertCite{soukhov2025family;textual}{accessibility}.
#'
#' ## Total Constrained Accessibility
#'
#' Allocates the system-wide total proportionally based on travel impedance
#' between origins and destinations. This measure uses the logic of a
#' total ~(or 'unconstrained' by Wilson's terms)~ constraint.
#'
#' Use this measure when the total quantity of **supply** OR **demand** in the
#' system is known and representing accessibility as a proportion of this total
#'  is meaningful.
#'
#' ### Requirement:
#' - Either `demand` or `supply` must be provided (cannot provide both).
#'
#' ### Interpretation:
#' - `active = TRUE` (*active accessibility*): Results represent the total
#' number of  **opportunities** (supply) accessible from each origin based on
#' region-relative travel impedance. The units are in 'supply' (e.g., jobs,
#' school seats).
#'   - If `detailed_results = FALSE`, outputs are aggregated and returned by
#'   origin.
#'   - If `detailed_results = TRUE`, OD-level flows are returned. Summing flows
#'   by origin equals the aggregated result.
#'
#' - `active = FALSE` (*passive accessibility*, the notion of market potential):
#' Results represent the total number of **population** (demand) that can reach
#' each destination based on region-relative travel impedance. The units are in
#' 'demand' (e.g., population).
#'   - If `detailed_results = FALSE`, outputs are aggregated by destination.
#'   - If `detailed_results = TRUE`, OD-level flows are returned. Summing flows
#'   by destination equals the aggregated result.
#'
#' ### Use cases:
#' - Active accessibility (aggregated):
#'   "How many jobs can be reached from origin zone A given its region-relative
#'   travel impedance?"
#'
#' - Active accessibility (flow-level):
#'   "How many jobs can be reached by flow A->1 given A->1's region-relative
#'   travel impedance?"
#'
#' - Passive accessibility (aggregated):
#'   "How many people can reach destination zone 1 given its region-relative
#'   travel impedance?"
#'
#' - Passive accessibility (flow-level):
#'   "How many people are reached by flow 1->A given 1->A's region-relative
#'   travel impedance?"
#'
#'
#' ## Singly Constrained Accessibility
#'
#' Allocates opportunities at each destination (or population at each origin)
#' proportionally based on travel impedance and the opposite marginal. This
#'  measure uses the logic of single constraint from
#'  \insertCite{wilson1971family;textual}{accessibility}.
#'
#' Use this measure when modeling **competition**, where both demand and supply
#' are conceptualised to influence accessibility but only one side is fixed.
#' The measure distributes flows so that totals match the constrained side
#' while weighting by travel impedance and the unconstrained side.
#'
#' ### Requirements:
#' - Both `demand` and `supply` must be provided (the logical for `active`
#' determines if either demand or supply is constrained).
#'
#' ### Interpretation:
#' - `active = TRUE` (*active accessibility*): constrains supply. Results
#' represent the total number of **opportunities** (supply) accessible from each
#'  origin based on region-relative travel impedance and population at the origin.
#'    The units are in 'supply' (e.g., jobs, school seats).
#'   - If `detailed_results = FALSE`, outputs are aggregated and returned by origin.
#'   - If `detailed_results = TRUE`, OD-level flows are returned. Summing flows
#'    by origin equals the aggregated result.
#'
#' - `active = FALSE` (*passive accessibility*, the notion of market potential):
#' constrains demand. Results represent the total number of
#' **population** (demand) that can reach each destination based on
#' region-relative travel impedance and opportunities at the destination. The
#' units are in 'demand' (e.g., population).
#'   - If `detailed_results = FALSE`, outputs are aggregated by destination.
#'   - If `detailed_results = TRUE`, OD-level flows are returned. Summing flows
#'   by destination equals the aggregated result.
#'
#' ### Use cases:
#' - Active accessibility (aggregated):
#'   "How many jobs can be reached from origin zone A given its region-relative
#'   travel impedance and demand?"
#'
#' - Active accessibility (flow-level):
#'   "How many jobs can be reached by flow A->1 given A->1's region-relative
#'   travel impedance and demand?"
#'
#' - Passive accessibility (aggregated):
#'   "How many people can reach destination zone 1 given its region-relative
#'   travel impedance and supply?"
#'
#' - Passive accessibility (flow-level):
#'   "How many people are reached by flow 1->A given 1->A's region-relative
#'   travel impedance and supply?"
#'
#' **NOTE:** the active form of this measure yields equivalent results to the
#'  `spatial_availability()` function, through different logic.
#'
#' ## Doubly Constrained Accessibility
#'
#' Allocates flows so supply at each destination matches demand at each origin.
#' It uses Wilson's *doubly-constrained* gravity model \insertCite{wilson1971family;textual}{accessibility}.
#'
#' The model uses iterative proportional fitting to update balancing factors in
#' order to calibrate OD flows on both margins (`A_i` for origins and `B_j` for
#' destinations) until convergence (i.e. the sum of `demand` and `supply` match).
#' This guarantees that flows satisfy both marginals while being weighted by
#' travel  impedance.
#'
#' ### Requirements:
#' - Both `demand` and `supply` must be provided.
#' - Unlike `total` and `singly`, `doubly` requires the sum of demand and supply
#' to match; otherwise, the model will not converge.
#'  - `active` must be `NULL`. Since supply must match demand, their units are
#'  the same and there is no distinction between 'active' and 'passive' notions.
#' - Only accepts`detailed_results = TRUE`.
#'
#' ### Interpretation:
#' - Results include OD-level flows (`flow`) along with balancing factors (`A_i`,
#' `B_j`) and travel impedance weights. The resulting flows represent the
#' distribution of demand and supply across all origin-destination pairs. NOTE:
#' OD flows are in flow units (jointly determined by demand and supply).
#'
#' ### Use cases:
#' - flow-level:
#' "What is the count of A->1 flows given A->1's region-relative travel impedance,
#'  demand and supply?"
#'
#' @references
#' \insertAllCited{}

#' @family Constrained accessibility
#'
#' @examples
#' # Load demo data shipped with the package
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' # Total-constrained (active accessibility, aggregated): returns units of
#' # accessible supply by origin (requires supply)
#' constrained_accessibility(
#'   travel_matrix   = travel_matrix,
#'   land_use_data   = land_use_data,
#'   travel_cost     = "travel_time",
#'   constraint      = "total",
#'   decay_function  = decay_exponential(0.1),
#'   demand          = NULL,
#'   supply          = "jobs",
#'   active          = TRUE,
#'   detailed_results = FALSE
#' )
#'
#' # Total-constrained (passive accessibility, aggregated): returns units of
#' # accessible demand by destination  (requires demand)
#' constrained_accessibility(
#'   travel_matrix  = travel_matrix,
#'   land_use_data  = land_use_data,
#'   travel_cost    = "travel_time",
#'   constraint     = "total",
#'   decay_function = decay_exponential(0.1),
#'   demand         = "population",
#'   supply         = NULL,
#'   active         = FALSE,
#'   detailed_results = FALSE
#' )
#'
#' # Singly-constrained (active accessibility, aggregated): returns units of
#' # accessible supply by origin (requires supply and demand)
#' constrained_accessibility(
#'   travel_matrix   = travel_matrix,
#'   land_use_data   = land_use_data,
#'   travel_cost     = "travel_time",
#'   constraint      = "singly",
#'   decay_function  = decay_exponential(0.1),
#'   demand          = "population",
#'   supply          = "jobs",
#'   active          = TRUE,
#'   detailed_results = FALSE
#' )
#'
#' # Doubly-constrained: returns units of flow (requires both demand and supply
#' # (totals that match) and `detailed_results = TRUE`)
#'
#' # Using a small toy dataset with matching totals.
#' tm_small <- data.table::data.table(
#'   expand.grid(from_id = c("1","2","3"), to_id = c("1","2","3"))
#' )
#' tm_small[, travel_time := c(10, 30, 15, 30, 10, 25, 15, 25, 10)]
#' lu_small <- data.table::data.table(
#'   id         = c("1","2","3"),
#'   population = c(4, 10, 6),   # sum = 20
#'   jobs       = c(7,  5,  8)   # sum = 20
#' )
#'
#' constrained_accessibility(
#'   travel_matrix   = tm_small,
#'   land_use_data   = lu_small,
#'   travel_cost     = "travel_time",
#'   constraint      = "doubly",
#'   decay_function  = decay_exponential(0.1),
#'   demand          = "population",
#'   supply          = "jobs",
#'   detailed_results = TRUE
#' )
#'
#' @export
constrained_accessibility <- function(travel_matrix,
                                      land_use_data,
                                      travel_cost,
                                      demand = NULL,
                                      supply = NULL,
                                      constraint,
                                      decay_function,
                                      active = NULL,
                                      error_threshold = 0.001,
                                      improvement_threshold = 1e-6,
                                      max_iterations = 1000,
                                      group_by = character(0),
                                      fill_missing_ids = TRUE,
                                      detailed_results = FALSE) {

  checkmate::assert_choice(constraint, c("total", "singly", "doubly"))
  checkmate::assert_string(travel_cost)
  checkmate::assert_string(demand, null.ok = TRUE)
  checkmate::assert_string(supply, null.ok = TRUE)
  assert_decay_function(decay_function)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(land_use_data, travel_matrix, opportunity = supply, demand = demand)
  checkmate::assert_logical(detailed_results, len = 1, any.missing = FALSE)
  assert_detailed_fill_missing_ids(fill_missing_ids, detailed_results)


  if (constraint == "doubly") {
    return(doubly_constrained(
      travel_matrix = travel_matrix,
      land_use_data = land_use_data,
      travel_cost = travel_cost,
      decay_function = decay_function,
      demand = demand,
      supply = supply,
      error_threshold = error_threshold,
      improvement_threshold = improvement_threshold,
      max_iterations = max_iterations,
      group_by = group_by,
      fill_missing_ids = fill_missing_ids,
      detailed_results = detailed_results
    ))
  }
  # For 'total' and 'singly' we require active to be TRUE or FALSE
  if (is.null(active)) {
    cli::cli_abort(
      "For {.val {constraint}}, active must be TRUE or FALSE.",
      call = NULL
    )
  }

  # Validate the relevant side (opportunity column) only
  # 'active = TRUE' -> supply-side is returned; 'active = FALSE' -> demand-side is returned
  opportunity_col <- if (active) supply else demand
  assert_land_use_data(land_use_data, travel_matrix, opportunity = opportunity_col)


  if (constraint == "singly") {
    return(singly_constrained(
      travel_matrix = travel_matrix,
      land_use_data = land_use_data,
      travel_cost = travel_cost,
      decay_function = decay_function,
      demand = demand,
      supply = supply,
      active = active,
      group_by = group_by,
      fill_missing_ids = fill_missing_ids,
      detailed_results = detailed_results
    ))
  }

  if (constraint == "total") {
    return(total_constrained(
      travel_matrix = travel_matrix,
      land_use_data = land_use_data,
      travel_cost = travel_cost,
      decay_function = decay_function,
      group_by = group_by,
      fill_missing_ids = fill_missing_ids,
      detailed_results = detailed_results,
      active = active,
      demand = if (!active) demand else NULL,
      supply = if (active) supply else NULL
    ))
  }


}
