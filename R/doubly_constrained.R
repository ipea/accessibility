#' Doubly constrained accessibility
#'
#' Calculates accessibility using Wilson's doubly-constrained gravity model.
#' This measure allocates flows between origins and destinations such that
#' origin totals equal demand and destination totals equal supply. Note: this is
#' an internal helper function used by [constrained_accessibility()] when
#' `constraint = "doubly"`.
#'
#' @name doubly_constrained
#' @keywords internal
#' @return A `data.table`/`data.frame` with origin-destination flows, balancing
#' factors (`A_i`, `B_j`), and doubly-constrained weights (`kappa_doubly`).
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
run_standalone_doubly_ipf <- function(
    data,
    land_use_data,
    demand,
    supply,
    error_threshold,
    improvement_threshold,
    max_iterations
) {

  # Prepare vectors and impedance matrix
  origins <- unique(data$from_id)
  destinations <- unique(data$to_id)

  O <- land_use_data[[demand]][match(origins, land_use_data$id)]
  D <- land_use_data[[supply]][match(destinations, land_use_data$id)]

  O[is.na(O)] <- 0
  D[is.na(D)] <- 0

  if (abs(sum(O) - sum(D)) > 1e-6) {
    cli::cli_abort(
      "For doubly-constrained, the sum of origins must equal the sum of destinations.
      NA values and ids missing from {.arg land_use_data} count as 0.",
      call = NULL
    )
  }

  if (sum(O) <= 0) {
    cli::cli_abort(
      "For doubly-constrained, the total demand and supply must be greater than 0.",
      call = NULL
    )
  }

  impedance_matrix <- matrix(
    0,
    nrow = length(origins),
    ncol = length(destinations),
    dimnames = list(origins, destinations)
  )

  impedance_matrix[
    cbind(
      match(data$from_id, origins),
      match(data$to_id, destinations)
    )
  ] <- data$opp_weight

  Ai <- rep(1, length(O))
  Bj <- rep(1, length(D))

  previous_error <- Inf
  iteration_count <- 0
  stop_reason <- ""

  repeat {

    iteration_count <- iteration_count + 1

    denominator_i <- drop(
      impedance_matrix %*% (Bj * D)
    )

    Ai <- data.table::fifelse(
      denominator_i > 0,
      1 / denominator_i,
      0
    )

    denominator_j <- drop(
      crossprod(
        impedance_matrix,
        Ai * O
      )
    )

    Bj_new <- data.table::fifelse(
      denominator_j > 0,
      1 / denominator_j,
      0
    )

    flow_from <- Ai * O *
      drop(impedance_matrix %*% (Bj_new * D))

    flow_to <- Bj_new * D * denominator_j

    error <- (
      sum(abs(O - flow_from)) +
        sum(abs(D - flow_to))
    ) / sum(O)

    error_change <- abs(previous_error - error)

    if (
      error < error_threshold ||
      error_change < improvement_threshold ||
      iteration_count >= max_iterations
    ) {

      Bj <- Bj_new

      stop_reason <- if (iteration_count >= max_iterations) {
        "Max iterations reached"
      } else if (error < error_threshold) {
        "Error threshold met"
      } else {
        "Slow improvement"
      }

      break
    }

    previous_error <- error
    Bj <- Bj_new
  }

  if (error >= error_threshold) {
    cli::cli_warn(
      "Doubly-constrained balancing did not converge ({stop_reason}
      after {iteration_count} iterations). Final error is
      {signif(error, 3)}."
    )
  }

  Tij <- outer(
    Ai * O,
    Bj * D
  ) * impedance_matrix

  kappa_matrix <- outer(
    Ai * O,
    Bj
  ) * impedance_matrix

  data.table::data.table(
    from_id = rep(origins, each = length(destinations)),
    to_id = rep(destinations, times = length(origins)),
    flow = as.vector(t(Tij)),
    A_i = rep(Ai, each = length(destinations)),
    B_j = rep(Bj, times = length(origins)),
    kappa_doubly = as.vector(t(kappa_matrix)),
    error = error
  )

}

run_grouped_doubly_ipf <- function(
    data,
    group_by,
    land_use_data,
    demand,
    supply,
    error_threshold,
    improvement_threshold,
    max_iterations
) {

  if ("decay_function_arg" %in% names(data)) {
    group_by <- c(group_by, "decay_function_arg")
  }

  if (length(group_by) == 0) {

    return(
      run_standalone_doubly_ipf(
        data = data,
        land_use_data = land_use_data,
        demand = demand,
        supply = supply,
        error_threshold = error_threshold,
        improvement_threshold = improvement_threshold,
        max_iterations = max_iterations
      )
    )
  }

  grouped_data <- split(
    data,
    by = group_by,
    keep.by = TRUE
  )

  results <- data.table::rbindlist(
    lapply(grouped_data, function(dt) {

      out <- run_standalone_doubly_ipf(
        data = dt,
        land_use_data = land_use_data,
        demand = demand,
        supply = supply,
        error_threshold = error_threshold,
        improvement_threshold = improvement_threshold,
        max_iterations = max_iterations
      )

      group_vals <- dt[1, ..group_by]

      for (g in group_by) {
        out[, (g) := group_vals[[g]]]
      }

      out

    }),
    fill = TRUE
  )

  return(results[])

}

doubly_constrained <- function(travel_matrix,
                               land_use_data,
                               travel_cost,
                               decay_function,
                               demand,
                               supply,
                               error_threshold = 0.001,
                               improvement_threshold = 1e-6,
                               max_iterations = 1000,
                               active,
                               group_by = character(0),
                               fill_missing_ids = TRUE,
                               detailed_results = FALSE
) {
  # Validate inputs
  checkmate::assert_string(demand)
  checkmate::assert_string(supply)
  checkmate::assert_number(error_threshold, lower = 0)
  checkmate::assert_number(improvement_threshold, lower = 0)
  checkmate::assert_int(max_iterations, lower = 1)

  assert_decay_function(decay_function)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(land_use_data, travel_matrix, opportunity = supply, demand = demand)

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

  # Run doubly-constrained model
  result <- run_grouped_doubly_ipf(
    data = data,
    group_by = group_by,
    land_use_data = land_use_data,
    demand = demand,
    supply = supply,
    error_threshold = error_threshold,
    improvement_threshold = improvement_threshold,
    max_iterations = max_iterations
  )

  if (exists("original_class")) {
    class(result) <- original_class
  }

  return(result[])

}
