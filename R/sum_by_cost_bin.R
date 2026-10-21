#' @keywords internal
sum_by_cost_bin <- function(data, groups, opportunity, travel_cost, cutoffs) {
  # sums the opportunities of each group by cost "bin": the index of the first
  # cutoff that the travel cost is lower than or equal to. cumulative sums over
  # the bins then give the opportunities within every cutoff with a single pass
  # over the travel matrix, instead of one pass per cutoff. cutoffs must be
  # sorted

  bin <- findInterval(data[[travel_cost]], cutoffs, left.open = TRUE) + 1L

  # rows with NA costs or costs above the last cutoff can't be reached. the
  # subset with keep always copies the columns, so the columns of the caller's
  # table are never sorted or updated by reference

  keep <- which(bin <= length(cutoffs))

  binned <- lapply(groups, function(col) data[[col]][keep])
  names(binned) <- groups
  binned$.bin <- bin[keep]

  # opportunities are summed as doubles, so integer sums don't overflow

  binned$.opp <- as.numeric(data[[opportunity]][keep])
  binned <- data.table::setDT(binned)

  binned_sums <- binned[
    ,
    .(.opp = sum(.opp), .n = .N),
    by = c(groups, ".bin")
  ]

  return(binned_sums)
}


#' @keywords internal
cumulative_sums_grid <- function(binned_sums,
                                 grid_groups,
                                 groups,
                                 n_cutoffs,
                                 integer_opportunity) {
  # one row per group (from grid_groups) and cutoff. bins that no row falls
  # into get 0 opportunities and 0 rows. the cumulative sums are doubles, so
  # they don't overflow, and are converted back to integers when the
  # opportunities are integers and the sums fit

  grid <- grid_groups[rep(seq_len(nrow(grid_groups)), each = n_cutoffs)]
  data.table::set(
    grid,
    j = ".bin",
    value = rep.int(seq_len(n_cutoffs), nrow(grid_groups))
  )

  grid[
    binned_sums,
    on = c(groups, ".bin"),
    `:=`(.opp = i..opp, .n = i..n)
  ]

  # the NAs are replaced on the whole columns, outside of by, which would
  # otherwise call fcoalesce() once per group

  data.table::set(
    grid,
    j = ".opp",
    value = data.table::fcoalesce(grid$.opp, 0)
  )
  data.table::set(grid, j = ".n", value = data.table::fcoalesce(grid$.n, 0L))
  grid[, `:=`(access = cumsum(.opp), .n = cumsum(.n)), by = c(groups)]
  grid[, .opp := NULL]

  if (integer_opportunity && all(grid$access <= .Machine$integer.max)) {
    data.table::set(grid, j = "access", value = as.integer(grid$access))
  }

  return(grid[])
}
