# Small internal helpers
make_tm_3x3 <- function() {
  tm <- data.table::data.table(
    expand.grid(from_id = c("1","2","3"), to_id = c("1","2","3"))
  )
  tm[, travel_time := c(10, 30, 15,  30, 10, 25,  15, 25, 10)]
  tm
}
make_lu_large <- function() {
  data.table::data.table(
    id         = c("1","2","3"),
    population = c(4, 10, 6),
    jobs       = c(160, 150, 180)
  )
}
make_lu_match20 <- function() {
  data.table::data.table(
    id         = c("1","2","3"),
    population = c(4, 10, 6),  # sum = 20
    jobs       = c(7,  5,  8)  # sum = 20
  )
}

exp_decay_01 <- decay_exponential(decay_value = 0.1)
pow_decay_3  <- decay_power(decay_value = 3)

# ------------------------------- TOTAL -------------------------------
test_that("total-constrained: preserves totals on supply/demand sides", {
  tm <- make_tm_3x3()
  lu <- make_lu_large()

  # Supply-side output (returns accessible opportunities)
  det_supply <- constrained_accessibility(
    constraint = "total",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = NULL,
    supply = "jobs",
    detailed_results = TRUE,
    active = TRUE
  )
  agg_supply <- constrained_accessibility(
    constraint = "total",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = NULL,
    supply = "jobs",
    detailed_results = FALSE,
    active = TRUE
  )

  # Demand-side output (returns accessible population)
  det_demand <- constrained_accessibility(
    constraint = "total",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = NULL,
    detailed_results = TRUE,
    active = FALSE
  )
  agg_demand <- constrained_accessibility(
    constraint = "total",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = NULL,
    detailed_results = FALSE,
    active = FALSE
  )

  expect_equal(sum(det_supply$supply), sum(lu$jobs))
  expect_equal(sum(agg_supply$supply), sum(lu$jobs))
  expect_equal(sum(det_demand$demand), sum(lu$population))
  expect_equal(sum(agg_demand$demand), sum(lu$population))
})

# ------------------------------ SINGLY -------------------------------
test_that("singly-constrained: preserves totals and kappa properties", {
  tm <- make_tm_3x3()
  lu <- make_lu_large()

  # Supply-constrained (returns accessible opportunities)
  det_supply <- constrained_accessibility(
    travel_matrix = tm,
    land_use_data = lu,
    constraint = "singly",
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = "jobs",
    detailed_results = TRUE,
    active = TRUE
  )
  agg_supply <- constrained_accessibility(
    constraint = "singly",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = "jobs",
    detailed_results = FALSE,
    active = TRUE
  )

  # Demand-constrained (returns accessible population)
  det_demand <- constrained_accessibility(
    constraint = "singly",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = "jobs",
    detailed_results = TRUE,
    active = FALSE
  )
  agg_demand <- constrained_accessibility(
    constraint = "singly",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = exp_decay_01,
    demand = "population",
    supply = "jobs",
    detailed_results = FALSE,
    active = FALSE
  )

  # Totals
  expect_equal(sum(det_supply$supply), sum(lu$jobs))
  expect_equal(sum(agg_supply$supply), sum(lu$jobs))
  expect_equal(sum(det_demand$demand), sum(lu$population))
  expect_equal(sum(agg_demand$demand), sum(lu$population))

  # κ normalization properties (these DO hold for singly)
  by_to   <- det_supply[, .(sum_k = sum(kappa_singly)),    by = to_id]
  by_from <- det_demand[, .(sum_k = sum(hatkappa_singly)), by = from_id]
  expect_true(all(abs(by_to$sum_k   - 1) < 1e-8))  # per-destination sums == 1
  expect_true(all(abs(by_from$sum_k - 1) < 1e-8))  # per-origin sums == 1
  expect_equal(sum(det_supply$kappa_singly),    length(unique(det_supply$to_id)))
  expect_equal(sum(det_demand$hatkappa_singly), length(unique(det_demand$from_id)))
})

# ------------------------------ DOUBLY -------------------------------
test_that("doubly-constrained: errors when totals mismatch", {
  tm <- make_tm_3x3()
  lu_bad <- data.table::copy(make_lu_match20())
  lu_bad[id == "3", jobs := jobs + 1]  # break equality

  expect_error(
    constrained_accessibility(
      constraint = "doubly",
      travel_matrix = tm,
      land_use_data = lu_bad,
      travel_cost = "travel_time",
      decay_function = exp_decay_01,
      demand = "population",
      supply = "jobs",
      detailed_results = TRUE,
      active = NULL
    ),
    # cli wraps long messages, so spaces may be line breaks
    "sum of origins must equal the sum of[[:space:]]+destinations"
  )
})



test_that("doubly-constrained: OD flows match marginals", {
  tm    <- make_tm_3x3()
  lu    <- make_lu_match20()
  decay <- pow_decay_3

  det <- constrained_accessibility(
    constraint = "doubly",
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    decay_function = decay,
    demand = "population",
    supply = "jobs",
    detailed_results = TRUE,
    active = NULL
  )

  # Robustly pick the numeric flow column
  candidate_cols <- c("flow", "supply", "demand")
  value_col <- intersect(candidate_cols, names(det))[1]
  expect_true(!is.null(value_col), info = "No flow/supply/demand column in detailed output")
  expect_true(is.numeric(det[[value_col]]), info = "Flow column must be numeric")

  # Sum flows by origin and destination
  by_origin <- det[, .(sum_flow = sum(get(value_col))), by = from_id]
  by_dest   <- det[, .(sum_flow = sum(get(value_col))), by = to_id]

  # Build expected marginals from land use
  O <- lu[match(by_origin$from_id, lu$id), population]
  D <- lu[match(by_dest$to_id,   lu$id), jobs]

  expect_equal(by_origin$sum_flow, O, tolerance = 1e-3)
  expect_equal(by_dest$sum_flow,   D, tolerance = 1e-3)
})


test_that("doubly-constrained: results don't depend on row order or sparsity", {
  ids <- c("1", "2", "3")
  cost <- matrix(
    c(0, 10, 25, 15, 0, 5, 30, 20, 0),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(ids, ids)
  )
  lu <- make_lu_match20()

  # independent iterative proportional fitting, as reference

  reference_flows <- function(weights) {
    a <- b <- rep(1, 3)
    for (k in 1:2000) {
      a <- 1 / as.vector(weights %*% (b * lu$jobs))
      b <- 1 / as.vector(t(weights) %*% (a * lu$population))
    }
    flows <- outer(a * lu$population, b * lu$jobs) * weights
    dimnames(flows) <- list(ids, ids)
    flows
  }

  run_doubly <- function(tm, land_use = lu) {
    constrained_accessibility(
      constraint = "doubly",
      travel_matrix = tm,
      land_use_data = land_use,
      travel_cost = "travel_time",
      decay_function = exp_decay_01,
      demand = "population",
      supply = "jobs",
      detailed_results = TRUE,
      error_threshold = 1e-10,
      improvement_threshold = 0
    )
  }

  to_major <- data.table::data.table(
    expand.grid(from_id = ids, to_id = ids, stringsAsFactors = FALSE)
  )
  to_major[, travel_time := cost[cbind(from_id, to_id)]]
  from_major <- to_major[order(from_id, to_id)]
  shuffled <- to_major[c(5, 9, 1, 7, 3, 8, 2, 6, 4)]

  expected <- reference_flows(exp(-0.1 * cost))
  for (tm in list(to_major, from_major, shuffled)) {
    result <- run_doubly(tm)
    expect_equal(
      result$flow,
      expected[cbind(result$from_id, result$to_id)],
      tolerance = 1e-6
    )
  }

  result <- run_doubly(to_major, lu[c(3, 1, 2)])
  expect_equal(
    result$flow,
    expected[cbind(result$from_id, result$to_id)],
    tolerance = 1e-6
  )

  # pairs missing from the travel matrix are unreachable

  sparse_weights <- exp(-0.1 * cost)
  sparse_weights["1", "3"] <- 0
  expected <- reference_flows(sparse_weights)

  result <- run_doubly(shuffled[!(from_id == "1" & to_id == "3")])
  expect_equal(
    result$flow,
    expected[cbind(result$from_id, result$to_id)],
    tolerance = 1e-6
  )
  expect_identical(result[from_id == "1" & to_id == "3"]$flow, 0)
})

test_that("doubly-constrained: errors when land_use_data misses an id", {
  # the validators also warn about the missing id

  expect_error(
    suppressWarnings(constrained_accessibility(
      constraint = "doubly",
      travel_matrix = make_tm_3x3(),
      land_use_data = make_lu_match20()[1:2],
      travel_cost = "travel_time",
      decay_function = exp_decay_01,
      demand = "population",
      supply = "jobs",
      detailed_results = TRUE
    )),
    regexp = "must list a non-NA demand"
  )
})

test_that("doubly-constrained: converges with very small impedance weights", {
  tm <- make_tm_3x3()
  tm[, travel_time := travel_time + 60]
  lu <- make_lu_match20()

  # exp(-0.5 * c) is ~1e-13 to 1e-19 here

  result <- expect_silent(
    constrained_accessibility(
      constraint = "doubly",
      travel_matrix = tm,
      land_use_data = lu,
      travel_cost = "travel_time",
      decay_function = decay_exponential(decay_value = 0.5),
      demand = "population",
      supply = "jobs",
      detailed_results = TRUE
    )
  )

  by_origin <- result[, .(flow = sum(flow)), by = from_id]
  by_destination <- result[, .(flow = sum(flow)), by = to_id]
  expect_equal(
    by_origin$flow,
    lu$population[match(by_origin$from_id, lu$id)],
    tolerance = 1e-3
  )
  expect_equal(
    by_destination$flow,
    lu$jobs[match(by_destination$to_id, lu$id)],
    tolerance = 1e-3
  )
})

test_that("doubly-constrained: warns when balancing doesn't converge", {
  expect_warning(
    constrained_accessibility(
      constraint = "doubly",
      travel_matrix = make_tm_3x3(),
      land_use_data = make_lu_match20(),
      travel_cost = "travel_time",
      decay_function = exp_decay_01,
      demand = "population",
      supply = "jobs",
      max_iterations = 1,
      detailed_results = TRUE
    ),
    regexp = "did not converge"
  )
})

test_that("fill_missing_ids fills missing combinations when using group_by", {
  tm <- make_tm_3x3()
  lu <- make_lu_match20()

  # bus doesn't serve origin 3, so the (3, bus) combination is missing

  tm_modes <- data.table::rbindlist(
    list(car = tm, bus = tm[from_id != "3"]),
    idcol = "mode"
  )

  run <- function(constraint, travel_matrix, group_by = "mode") {
    constrained_accessibility(
      constraint = constraint,
      travel_matrix = travel_matrix,
      land_use_data = lu,
      travel_cost = "travel_time",
      decay_function = exp_decay_01,
      demand = "population",
      supply = "jobs",
      active = TRUE,
      group_by = group_by
    )
  }

  for (constraint in c("total", "singly")) {
    result <- run(constraint, tm_modes)
    expect_identical(nrow(result), 6L)
    expect_identical(result[from_id == "3" & mode == "bus"]$supply, 0)
  }

  # singly-constrained car results don't depend on the bus rows

  result <- run("singly", tm_modes)
  ungrouped <- run("singly", tm, group_by = character(0))
  car <- result[mode == "car"]
  expect_equal(
    car$supply,
    ungrouped$supply[match(car$from_id, ungrouped$from_id)]
  )
})

test_that("total-constrained: doesn't add an index to land_use_data", {
  lu <- make_lu_large()

  # data.table auto-indexing is only triggered with character ids

  tm <- make_tm_3x3()
  tm[, `:=`(from_id = as.character(from_id), to_id = as.character(to_id))]

  constrained_accessibility(
    travel_matrix = tm,
    land_use_data = lu,
    travel_cost = "travel_time",
    supply = "jobs",
    demand = "population",
    constraint = "total",
    decay_function = exp_decay_01,
    active = TRUE
  )

  expect_true(is.null(attr(lu, "index")))
})
