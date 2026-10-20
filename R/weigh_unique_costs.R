#' @keywords internal
weigh_unique_costs <- function(travel_cost, weigh) {
  # decay functions that use exp() or ^ are slow on large travel matrices.
  # travel costs are usually rounded (e.g. integer minutes), so we calculate
  # the weights once per unique cost and map them back to every cost. weigh()
  # takes a cost vector and returns a list of weight vectors. finding the
  # unique costs is slower than weighting all costs when costs are continuous,
  # so we first check a sample of the costs

  sample_costs <- travel_cost[seq_len(min(length(travel_cost), 10000L))]

  if (length(unique(sample_costs)) > length(sample_costs) / 2) {
    return(weigh(travel_cost))
  }

  unique_costs <- unique(travel_cost)

  if (length(unique_costs) > length(travel_cost) / 2) {
    return(weigh(travel_cost))
  }

  cost_index <- match(travel_cost, unique_costs)

  weights_list <- lapply(
    weigh(unique_costs),
    function(weights) {
      weights <- weights[cost_index]
      names(weights) <- names(travel_cost)
      weights
    }
  )

  return(weights_list)
}
