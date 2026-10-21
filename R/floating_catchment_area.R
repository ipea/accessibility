#' Floating catchment area accessibility
#'
#' Calculates accessibility accounting for the competition of resources using a
#' measure from the floating catchment area (FCA) family. Please see the details
#' for the available FCA measures.
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @template demand
#' @param method A string. Which floating catchment area measure to use.
#'   Current available options are `"2sfca"` and `"bfca"`. More info in the
#'   details.
#' @template decay_function
#' @template group_by
#' @template fill_missing_ids_combinations
#'
#' @return A data frame containing the accessibility estimates for each origin
#'   in the travel matrix.
#'
#' @section Details:
#' The package currently includes two built-in FCA measures:
#'
#' - 2SFCA - the 2-Step Floating Catchment Area measure was the first
#' accessibility metric in the FCA family. It was originally proposed by
#' \insertCite{luo2003measures;textual}{accessibility}.
#'
#' - BFCA - the Balanced Floating Catchment Area measure calculates
#' accessibility accounting for competition effects while simultaneously
#' correcting for issues of inflation of demand and service levels that are
#' present in other FCA measures. It was originally proposed by
#' \insertCite{paez2019demand;textual}{accessibility} and named in
#' \insertCite{pereira2021geographic;textual}{accessibility}.
#'
#' @references
#' \insertAllCited{}
#'
#' @family Floating catchment area
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' # 2SFCA with a step decay function
#' df <- floating_catchment_area(
#'   travel_matrix,
#'   land_use_data,
#'   method = "2sfca",
#'   decay_function = decay_binary(cutoff = 50),
#'   opportunity = "jobs",
#'   travel_cost = "travel_time",
#'   demand = "population"
#' )
#' head(df)
#'
#'
#' # BFCA with an exponential decay function
#' df <- floating_catchment_area(
#'   travel_matrix,
#'   land_use_data,
#'   method = "bfca",
#'   decay_function = decay_exponential(decay_value = 0.5),
#'   opportunity = "jobs",
#'   travel_cost = "travel_time",
#'   demand = "population"
#' )
#' head(df)
#'
#' @export
floating_catchment_area <- function(travel_matrix,
                                    land_use_data,
                                    opportunity,
                                    travel_cost,
                                    demand,
                                    method,
                                    decay_function,
                                    group_by = character(0),
                                    fill_missing_ids = TRUE) {
  checkmate::assert(
    checkmate::check_string(method),
    checkmate::check_names(method, subset.of = c("2sfca", "bfca")),
    combine = "and"
  )
  checkmate::assert_string(opportunity)
  checkmate::assert_string(travel_cost)
  checkmate::assert_string(demand)
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)
  assert_decay_function(decay_function)
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

  merge_by_reference(
    data,
    land_use_data,
    opportunity,
    left_df_idcol = "to_id",
    na_as_zero = TRUE
  )
  merge_by_reference(
    data,
    land_use_data,
    demand,
    left_df_idcol = "from_id",
    na_as_zero = TRUE
  )

  data <- apply_gravity_measure(data, decay_function, travel_cost)

  groups <- c("from_id", group_by)
  if ("decay_function_arg" %in% names(data)) {
    groups <- c(groups, "decay_function_arg")
  }

  warn_extra_cols(
    travel_matrix,
    travel_cost,
    group_id = "from_id",
    groups = groups
  )

  fca_function <- if (method == "2sfca") {
    fca_2sfca
  } else {
    fca_bfca
  }

  access <- fca_function(data, opportunity, demand, setdiff(groups, "from_id"))

  if (fill_missing_ids) {
    access <- fill_missing_ids(access, travel_matrix, groups)
  }

  data.table::setnames(access, c("from_id", "access"), c("id", opportunity))

  if (exists("original_class")) class(access) <- original_class

  return(access)
}


#' @keywords internal
fca_2sfca <- function(data, opportunity, demand, group_by) {
  .opportunity_colname <- opportunity
  .demand_colname <- demand

  # step 1a - calculate the demand to each destination as the weight between
  # each od pair multiplied by the number of people at the origin

  # products are calculated before aggregating, so the sums are optimized by
  # data.table (GForce)

  data[, .weighted_demand := get(.demand_colname) * opp_weight]
  data[
    ,
    pop_served := sum(.weighted_demand, na.rm = TRUE),
    by = c("to_id", group_by)
  ]
  data[, .weighted_demand := NULL]

  # step 1b - calculate the provider-to-population ratio (ppr) of a destination
  # as number of opportunities/resources located at it divided by the
  # population it serves

  data[, ppr := get(.opportunity_colname) / pop_served]

  # step 2 - calculate accessibility at each origin i as the sum of the
  # multiplication between the ppr of destination j and the weight between od
  # pair ij

  data[, .weighted_ppr := ppr * opp_weight]
  access <- data[
    ,
    .(access = sum(.weighted_ppr, na.rm = TRUE)),
    by = c("from_id", group_by)
  ]

  return(access)
}


#' @keywords internal
fca_bfca <- function(data, opportunity, demand, group_by) {
  .opportunity_colname <- opportunity
  .demand_colname <- demand

  # calculate balanced (normalized) opp_weight by origin and by destination.
  # products and totals are calculated in separate steps, so the sums are
  # optimized by data.table (GForce)

  data[, .total_weight := sum(opp_weight), by = c("from_id", group_by)]
  data[, balanced_opp_weight_i := opp_weight / .total_weight]
  data[, .total_weight := sum(opp_weight), by = c("to_id", group_by)]
  data[, balanced_opp_weight_j := opp_weight / .total_weight]
  data[, .total_weight := NULL]

  # step 1a - calculate the balanced demand to each destination as the balanced
  # weight by origin multiplied by the number of people at the origin

  data[, .weighted_demand := get(.demand_colname) * balanced_opp_weight_i]
  data[
    ,
    balanced_pop_served := sum(.weighted_demand, na.rm = TRUE),
    by = c("to_id", group_by)
  ]
  data[, .weighted_demand := NULL]

  # step 1b - calculate the balanced provider-to-population ratio
  # (balanced_ppr) of a destination as number of opportunities/resources
  # located at it divided by the balanced demand

  data[, balanced_ppr := get(.opportunity_colname) / balanced_pop_served]

  # step 2 - calculate accessibility at each origin i as the sum of the
  # multiplication between the balanced_ppr of destination j and the balanced
  # weight by destination between od pair ij

  data[, .weighted_ppr := balanced_ppr * balanced_opp_weight_j]
  access <- data[
    ,
    .(access = sum(.weighted_ppr, na.rm = TRUE)),
    by = c("from_id", group_by)
  ]

  return(access)
}
