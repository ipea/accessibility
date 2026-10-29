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
    max_iterations,
    group_label = NULL
) {

  # with group_by or several decay values, messages name the group they refer
  # to, so a failing group can be told apart from the others

  in_group <- if (is.null(group_label)) {
    character(0)
  } else {
    c("i" = "In group {group_label}.")
  }

  # Prepare vectors and impedance matrix
  origins <- unique(data$from_id)
  destinations <- unique(data$to_id)

  O <- land_use_data[[demand]][match(origins, land_use_data$id)]
  D <- land_use_data[[supply]][match(destinations, land_use_data$id)]

  # ids missing from land_use_data and NA values are treated as 0. this keeps
  # the balancing well-defined and matches merge_by_reference(na_as_zero = TRUE)

  O[is.na(O)] <- 0
  D[is.na(D)] <- 0

  if (abs(sum(O) - sum(D)) > 1e-6) {
    cli::cli_abort(
      c(
        "For doubly-constrained, the sum of origins must equal the sum of
        destinations. NA values and ids missing from {.arg land_use_data}
        count as 0.",
        in_group
      ),
      call = NULL
    )
  }

  if (sum(O) <= 0) {
    cli::cli_abort(
      c(
        "For doubly-constrained, the total demand and supply must be greater
        than 0.",
        in_group
      ),
      call = NULL
    )
  }

  # the impedance matrix is filled by matching origin and destination ids, so
  # the row order of travel_matrix doesn't matter and each weight goes to the
  # right pair. pairs missing from travel_matrix are unreachable (weight 0)

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

    # a null denominator means the origin reaches no destination with
    # weighted supply, so its factor is 0 (instead of Inf) and it gets no flow

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

    # likewise, a destination that no origin with weighted demand reaches gets
    # a factor of 0

    Bj_new <- data.table::fifelse(
      denominator_j > 0,
      1 / denominator_j,
      0
    )

    # the row and column sums of the flows are calculated from the factors,
    # without building the flow matrix

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
        "max iterations reached"
      } else if (error < error_threshold) {
        "error threshold met"
      } else {
        "slow improvement"
      }

      break
    }

    previous_error <- error
    Bj <- Bj_new
  }

  if (error >= error_threshold) {
    cli::cli_warn(
      c(
        "Doubly-constrained balancing did not converge ({stop_reason} after
        {iteration_count} iteration{?s}). Final error is {signif(error, 3)},
        above {.arg error_threshold} ({error_threshold}), so flows don't fully
        match the demand and supply totals. Consider increasing
        {.arg max_iterations} or decreasing {.arg improvement_threshold}.",
        in_group
      )
    )
  }

  Tij <- outer(
    Ai * O,
    Bj * D
  ) * impedance_matrix

  # kappa_doubly is the allocation weight kappa_ij = A_i * O_i * B_j * f(c_ij),
  # so that the flow is T_ij = kappa_ij * D_j

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

  # drop = TRUE skips unused factor levels and level combinations that don't
  # occur in the data, which would otherwise be empty groups

  grouped_data <- split(
    data,
    by = group_by,
    keep.by = TRUE,
    drop = TRUE
  )

  results <- data.table::rbindlist(
    lapply(grouped_data, function(dt) {

      group_vals <- dt[1, ..group_by]
      group_label <- paste0(
        group_by,
        " = ",
        vapply(group_vals, as.character, character(1)),
        collapse = ", "
      )

      out <- run_standalone_doubly_ipf(
        data = dt,
        land_use_data = land_use_data,
        demand = demand,
        supply = supply,
        error_threshold = error_threshold,
        improvement_threshold = improvement_threshold,
        max_iterations = max_iterations,
        group_label = group_label
      )

      for (g in group_by) {
        out[, (g) := group_vals[[g]]]
      }

      out

    }),
    fill = TRUE
  )

  # group columns go right after the ids, as in the other constraints

  data.table::setcolorder(results, c("from_id", "to_id", group_by))

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
