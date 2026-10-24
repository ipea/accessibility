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

# # ------------------------------- TOTAL (6 tests) -------------------------------
# test_that("total-constrained: preserves totals on supply/demand sides", {
#   tm <- make_tm_3x3()
#   lu <- make_lu_large()
#
#   # Supply-side output (returns accessible opportunities)
#   det_supply <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = NULL,
#     supply = "jobs",
#     detailed_results = TRUE,
#     active = TRUE
#   )
#   agg_supply <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = NULL,
#     supply = "jobs",
#     detailed_results = FALSE,
#     active = TRUE
#   )
#
#   # Demand-side output (returns accessible population)
#   det_demand <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = NULL,
#     detailed_results = TRUE,
#     active = FALSE
#   )
#   agg_demand <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = NULL,
#     detailed_results = FALSE,
#     active = FALSE
#   )
#
#   expect_equal(sum(det_supply$supply), sum(lu$jobs))
#   expect_equal(sum(agg_supply$supply), sum(lu$jobs))
#   expect_equal(sum(det_demand$demand), sum(lu$population))
#   expect_equal(sum(agg_demand$demand), sum(lu$population))
# })

# test_that("total-constrained active multiple decay results equal single-decay runs", {
#
#   # creating a 11x11 OD matrix, meaning 121 OD pairs
#   ids <- as.character(1:11)
#
#   tm <- data.table::CJ(
#     from_id = ids,
#     to_id = ids
#   )
#
#   # assigning travel times that are abs(i-j) * 15, and 180 between 1->11 and 11->1
#   tm[, travel_time := abs(
#     as.integer(from_id) - as.integer(to_id)) * 15]
#
#   tm[from_id == "1" & to_id == "11", travel_time := 180]
#   tm[from_id == "11" & to_id == "1", travel_time := 180]
#
#   #assigning population, and jobs to each id.
#   lu <- data.table(
#     id = ids,
#     population = c(
#       100, 0, 250, 50, 0,
#       400, 120, 80, 0, 200, 25
#     ), # sums to 1225
#     jobs = c(
#       0, 500, 50, 0, 100,
#       250, 0, 300, 75, 0, 150
#     ) # sums to 1425
#   )
#
#   multi <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(c(0.05, 0.20)),
#     supply = "jobs",
#     active = TRUE
#   )
#
#   run_005 <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.05),
#     supply = "jobs",
#     active = TRUE
#   )
#
#   run_020 <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.20),
#     supply = "jobs",
#     active = TRUE
#   )
#
#   # Does the multi-decay run result exactly the same values as a standalone run with decay=0.05?
#   expect_equal(
#     multi[decay_function_arg == 0.05][order(from_id)]$supply,
#     run_005[order(from_id)]$supply
#   )
#
#   # Does the multi-decay run result exactly the same values as a standalone run with decay=0.20?
#   expect_equal(
#     multi[decay_function_arg == 0.20][order(from_id)]$supply,
#     run_020[order(from_id)]$supply
#   )
#
#   # Does each decay scenario preserve the regional total opportunities?
#   totals <- multi[
#     ,
#     .(total_supply = sum(supply)),
#     by = decay_function_arg
#   ]
#
#   expect_equal(
#     totals$total_supply,
#     rep(sum(lu$jobs), 2)
#   )
# })
#
# test_that("total-constrained passive multiple decay values equal separate runs", {
#
#   ids <- as.character(1:11)
#
#   tm <- data.table::CJ(
#     from_id = ids,
#     to_id = ids
#   )
#
#   tm[, travel_time := abs(
#     as.integer(from_id) - as.integer(to_id)
#   ) * 15]
#
#   lu <- data.table(
#     id = ids,
#     population = c(
#       100, 0, 250, 50, 0,
#       400, 120, 80, 0, 200, 25
#     ),
#     jobs = c(
#       0, 500, 50, 0, 100,
#       250, 0, 300, 75, 0, 150
#     )
#   )
#
#   multi <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(c(0.05, 0.20)),
#     demand = "population",
#     active = FALSE
#   )
#
#   run_005 <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.05),
#     demand = "population",
#     active = FALSE
#   )
#
#   run_020 <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.20),
#     demand = "population",
#     active = FALSE
#   )
#
#   expect_equal(
#     multi[decay_function_arg == 0.05][order(to_id)]$demand,
#     run_005[order(to_id)]$demand
#   )
#
#   expect_equal(
#     multi[decay_function_arg == 0.20][order(to_id)]$demand,
#     run_020[order(to_id)]$demand
#   )
#
#   totals <- multi[
#     ,
#     .(total_demand = sum(demand)),
#     by = decay_function_arg
#   ]
#
#   expect_equal(
#     totals$total_demand,
#     rep(sum(lu$population), 2)
#   )
# })
#
# test_that("total-constrained grouped results equal standalone results", {
#
#   tm <- make_tm_3x3()
#   lu <- make_lu_match20()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)
#     ),
#     idcol = "mode"
#   )
#
#   grouped <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode"
#   )
#
#   standalone <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     supply = "jobs",
#     active = TRUE
#   )
#
#   expect_equal(
#     grouped[mode == "car"][order(from_id)]$supply,
#     standalone[order(from_id)]$supply
#   )
#
#   expect_equal(
#     grouped[mode == "bus"][order(from_id)]$supply,
#     standalone[order(from_id)]$supply
#   )
# })
#
# test_that("total-constrained preserves grouping variables in detailed and aggregated outputs", {
#
#   tm <- make_tm_3x3()
#   lu <- make_lu_match20()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)
#     ),
#     idcol = "mode"
#   )
#
#   decay <- decay_exponential(c(0.1, 0.5))
#
#   detailed <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay,
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode",
#     detailed_results = TRUE
#   )
#
#   aggregated <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay,
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode",
#     detailed_results = FALSE
#   )
#
#   # detailed output preserves grouping variables
#
#   expect_true("mode" %in% names(detailed))
#   expect_true("decay_function_arg" %in% names(detailed))
#
#   expect_equal(
#     sort(unique(detailed$mode)),
#     c("bus", "car")
#   )
#
#   expect_equal(
#     sort(unique(detailed$decay_function_arg)),
#     c(0.1, 0.5)
#   )
#
#   # aggregated output preserves grouping variables
#
#   expect_true("mode" %in% names(aggregated))
#   expect_true("decay_function_arg" %in% names(aggregated))
#
#   expect_equal(
#     sort(unique(aggregated$mode)),
#     c("bus", "car")
#   )
#
#   expect_equal(
#     sort(unique(aggregated$decay_function_arg)),
#     c(0.1, 0.5)
#   )
#
#   # 3 origins × 2 modes × 2 decay values
#
#   expect_equal(nrow(aggregated), 12L)
# })
#
# test_that("total-constrained (active) fills missing group combinations", {
#
#   tm <- make_tm_3x3()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)[from_id != "3"]
#     ),
#     idcol = "mode"
#   )
#
#   result <- constrained_accessibility(
#     constraint = "total",
#     travel_matrix = tm_modes,
#     land_use_data = make_lu_match20(),
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode",
#     fill_missing_ids = TRUE
#   )
#
#   expect_equal(
#     result[from_id == "3" & mode == "bus"]$supply,
#     0
#   )
# })
#
# # ------------------------------ SINGLY (6 tests)-------------------------------
# test_that("singly-constrained: preserves totals and kappa properties", {
#   tm <- make_tm_3x3()
#   lu <- make_lu_large()
#
#   # Supply-constrained (returns accessible opportunities)
#   det_supply <- constrained_accessibility(
#     travel_matrix = tm,
#     land_use_data = lu,
#     constraint = "singly",
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     detailed_results = TRUE,
#     active = TRUE
#   )
#   agg_supply <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     detailed_results = FALSE,
#     active = TRUE
#   )
#
#   # Demand-constrained (returns accessible population)
#   det_demand <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     detailed_results = TRUE,
#     active = FALSE
#   )
#   agg_demand <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     detailed_results = FALSE,
#     active = FALSE
#   )
#
#   # Totals
#   expect_equal(sum(det_supply$supply), sum(lu$jobs))
#   expect_equal(sum(agg_supply$supply), sum(lu$jobs))
#   expect_equal(sum(det_demand$demand), sum(lu$population))
#   expect_equal(sum(agg_demand$demand), sum(lu$population))
#
#   # κ normalization properties (these DO hold for singly)
#   by_to   <- det_supply[, .(sum_k = sum(kappa_singly)),    by = to_id]
#   by_from <- det_demand[, .(sum_k = sum(hatkappa_singly)), by = from_id]
#   expect_true(all(abs(by_to$sum_k   - 1) < 1e-8))  # per-destination sums == 1
#   expect_true(all(abs(by_from$sum_k - 1) < 1e-8))  # per-origin sums == 1
#   expect_equal(sum(det_supply$kappa_singly),    length(unique(det_supply$to_id)))
#   expect_equal(sum(det_demand$hatkappa_singly), length(unique(det_demand$from_id)))
# })
#
# # test_that("singly-constrained active multiple decay values equal separate runs", {
#
#   ids <- as.character(1:11)
#
#   tm <- data.table::CJ(
#     from_id = ids,
#     to_id = ids
#   )
#
#   tm[, travel_time := abs(
#     as.integer(from_id) - as.integer(to_id)
#   ) * 15]
#
#   tm[from_id == "1" & to_id == "11", travel_time := 180]
#   tm[from_id == "11" & to_id == "1", travel_time := 180]
#
#   lu <- data.table(
#     id = ids,
#     population = c(
#       100, 0, 250, 50, 0,
#       400, 120, 80, 0, 200, 25
#     ),
#     jobs = c(
#       0, 500, 50, 0, 100,
#       250, 0, 300, 75, 0, 150
#     )
#   )
#
#   multi <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(c(0.05, 0.20)),
#     demand = "population",
#     supply = "jobs",
#     active = TRUE
#   )
#
#   run_005 <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.05),
#     demand = "population",
#     supply = "jobs",
#     active = TRUE
#   )
#
#   run_020 <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.20),
#     demand = "population",
#     supply = "jobs",
#     active = TRUE
#   )
#   # Does the multi-decay run result exactly the same values as a standalone run with decay=0.05?
#   expect_equal(
#     multi[decay_function_arg == 0.05][order(from_id)]$supply,
#     run_005[order(from_id)]$supply
#   )
#   # Does the multi-decay run result exactly the same values as a standalone run with decay=0.20?
#   expect_equal(
#     multi[decay_function_arg == 0.20][order(from_id)]$supply,
#     run_020[order(from_id)]$supply
#   )
#   # Does each decay scenario preserve the regional total opportunities?
#   totals <- multi[
#     ,
#     .(total_supply = sum(supply)),
#     by = decay_function_arg
#   ]
#
#   expect_equal(
#     totals$total_supply,
#     rep(sum(lu$jobs), 2)
#   )
# })
#
# test_that("singly-constrained passive multiple decay values equal separate runs", {
#
#   ids <- as.character(1:11)
#
#   tm <- data.table::CJ(
#     from_id = ids,
#     to_id = ids
#   )
#
#   tm[, travel_time := abs(
#     as.integer(from_id) - as.integer(to_id)
#   ) * 15]
#
#   lu <- data.table(
#     id = ids,
#     population = c(
#       100, 0, 250, 50, 0,
#       400, 120, 80, 0, 200, 25
#     ),
#     jobs = c(
#       0, 500, 50, 0, 100,
#       250, 0, 300, 75, 0, 150
#     )
#   )
#
#   multi <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(c(0.05, 0.20)),
#     demand = "population",
#     supply = "jobs",
#     active = FALSE
#   )
#
#   run_005 <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.05),
#     demand = "population",
#     supply = "jobs",
#     active = FALSE
#   )
#
#   run_020 <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay_exponential(0.20),
#     demand = "population",
#     supply = "jobs",
#     active = FALSE
#   )
#
#   expect_equal(
#     multi[decay_function_arg == 0.05][order(to_id)]$demand,
#     run_005[order(to_id)]$demand
#   )
#
#   expect_equal(
#     multi[decay_function_arg == 0.20][order(to_id)]$demand,
#     run_020[order(to_id)]$demand
#   )
#
#   totals <- multi[
#     ,
#     .(total_demand = sum(demand)),
#     by = decay_function_arg
#   ]
#
#   expect_equal(
#     totals$total_demand,
#     rep(sum(lu$population), 2)
#   )
# })


# test_that("singly-constrained preserves grouping variables in detailed outputs", {
#
#   tm <- make_tm_3x3()
#   lu <- make_lu_match20()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)
#     ),
#     idcol = "mode"
#   )
#
#   decay <- decay_exponential(c(0.1, 0.5))
#
#   # active detailed output
#   result_active <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay,
#     demand = "population",
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode",
#     detailed_results = TRUE
#   )
#
#   expect_true("mode" %in% names(result_active))
#   expect_true("decay_function_arg" %in% names(result_active))
#
#   expect_equal(
#     sort(unique(result_active$mode)),
#     c("bus", "car")
#   )
#
#   expect_equal(
#     sort(unique(result_active$decay_function_arg)),
#     c(0.1, 0.5)
#   )
#
#   # passive detailed output
#   result_passive <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay,
#     demand = "population",
#     supply = "jobs",
#     active = FALSE,
#     group_by = "mode",
#     detailed_results = TRUE
#   )
#
#   expect_true("mode" %in% names(result_passive))
#   expect_true("decay_function_arg" %in% names(result_passive))
#
#   expect_equal(
#     sort(unique(result_passive$mode)),
#     c("bus", "car")
#   )
#
#   expect_equal(
#     sort(unique(result_passive$decay_function_arg)),
#     c(0.1, 0.5)
#   )
# })
#
# test_that("singly-constrained grouped results equal standalone results", {
#
#   tm <- make_tm_3x3()
#   lu <- make_lu_match20()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)
#     ),
#     idcol = "mode"
#   )
#
#   # active
#   grouped_active <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode"
#   )
#
#   standalone_active <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     active = TRUE
#   )
#
#   expect_equal(
#     grouped_active[mode == "car"][order(from_id)]$supply,
#     standalone_active[order(from_id)]$supply
#   )
#
#   expect_equal(
#     grouped_active[mode == "bus"][order(from_id)]$supply,
#     standalone_active[order(from_id)]$supply
#   )
#
#   # passive
#   grouped_passive <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm_modes,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     active = FALSE,
#     group_by = "mode"
#   )
#
#   standalone_passive <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     active = FALSE
#   )
#
#   expect_equal(
#     grouped_passive[mode == "car"][order(to_id)]$demand,
#     standalone_passive[order(to_id)]$demand
#   )
#
#   expect_equal(
#     grouped_passive[mode == "bus"][order(to_id)]$demand,
#     standalone_passive[order(to_id)]$demand
#   )
# })
#
# test_that("singly-constrained (active) fills missing group combinations", {
#
#   tm <- make_tm_3x3()
#
#   tm_modes <- data.table::rbindlist(
#     list(
#       car = data.table::copy(tm),
#       bus = data.table::copy(tm)[from_id != "3"]
#     ),
#     idcol = "mode"
#   )
#
#   result <- constrained_accessibility(
#     constraint = "singly",
#     travel_matrix = tm_modes,
#     land_use_data = make_lu_match20(),
#     travel_cost = "travel_time",
#     decay_function = exp_decay_01,
#     demand = "population",
#     supply = "jobs",
#     active = TRUE,
#     group_by = "mode",
#     fill_missing_ids = TRUE
#   )
#
#   expect_equal(
#     result[from_id == "3" & mode == "bus"]$supply,
#     0
#   )
# })

# # ------------------------------ DOUBLY -------------------------------
# test_that("doubly-constrained: errors when totals mismatch", {
#   tm <- make_tm_3x3()
#   lu_bad <- data.table::copy(make_lu_match20())
#   lu_bad[id == "3", jobs := jobs + 1]  # break equality
#
#   expect_error(
#     constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = tm,
#       land_use_data = lu_bad,
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE,
#       active = NULL
#     ),
#     # cli wraps long messages, so spaces may be line breaks
#     "sum of origins must equal the sum of[[:space:]]+destinations"
#   )
# })
#
#
#
# test_that("doubly-constrained: OD flows match marginals", {
#   tm    <- make_tm_3x3()
#   lu    <- make_lu_match20()
#   decay <- pow_decay_3
#
#   det <- constrained_accessibility(
#     constraint = "doubly",
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     decay_function = decay,
#     demand = "population",
#     supply = "jobs",
#     detailed_results = TRUE,
#     active = NULL
#   )
#
#   # Robustly pick the numeric flow column
#   candidate_cols <- c("flow", "supply", "demand")
#   value_col <- intersect(candidate_cols, names(det))[1]
#   expect_true(!is.null(value_col), info = "No flow/supply/demand column in detailed output")
#   expect_true(is.numeric(det[[value_col]]), info = "Flow column must be numeric")
#
#   # Sum flows by origin and destination
#   by_origin <- det[, .(sum_flow = sum(get(value_col))), by = from_id]
#   by_dest   <- det[, .(sum_flow = sum(get(value_col))), by = to_id]
#
#   # Build expected marginals from land use
#   O <- lu[match(by_origin$from_id, lu$id), population]
#   D <- lu[match(by_dest$to_id,   lu$id), jobs]
#
#   expect_equal(by_origin$sum_flow, O, tolerance = 1e-3)
#   expect_equal(by_dest$sum_flow,   D, tolerance = 1e-3)
# })
#
#
# test_that("doubly-constrained: results don't depend on row order or sparsity", {
#   ids <- c("1", "2", "3")
#   cost <- matrix(
#     c(0, 10, 25, 15, 0, 5, 30, 20, 0),
#     nrow = 3,
#     byrow = TRUE,
#     dimnames = list(ids, ids)
#   )
#   lu <- make_lu_match20()
#
#   # independent iterative proportional fitting, as reference
#
#   reference_flows <- function(weights) {
#     a <- b <- rep(1, 3)
#     for (k in 1:2000) {
#       a <- 1 / as.vector(weights %*% (b * lu$jobs))
#       b <- 1 / as.vector(t(weights) %*% (a * lu$population))
#     }
#     flows <- outer(a * lu$population, b * lu$jobs) * weights
#     dimnames(flows) <- list(ids, ids)
#     flows
#   }
#
#   run_doubly <- function(tm, land_use = lu) {
#     constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = tm,
#       land_use_data = land_use,
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE,
#       error_threshold = 1e-10,
#       improvement_threshold = 0
#     )
#   }
#
#   to_major <- data.table::data.table(
#     expand.grid(from_id = ids, to_id = ids, stringsAsFactors = FALSE)
#   )
#   to_major[, travel_time := cost[cbind(from_id, to_id)]]
#   from_major <- to_major[order(from_id, to_id)]
#   shuffled <- to_major[c(5, 9, 1, 7, 3, 8, 2, 6, 4)]
#
#   expected <- reference_flows(exp(-0.1 * cost))
#   for (tm in list(to_major, from_major, shuffled)) {
#     result <- run_doubly(tm)
#     expect_equal(
#       result$flow,
#       expected[cbind(result$from_id, result$to_id)],
#       tolerance = 1e-6
#     )
#   }
#
#   result <- run_doubly(to_major, lu[c(3, 1, 2)])
#   expect_equal(
#     result$flow,
#     expected[cbind(result$from_id, result$to_id)],
#     tolerance = 1e-6
#   )
#
#   # pairs missing from the travel matrix are unreachable
#
#   sparse_weights <- exp(-0.1 * cost)
#   sparse_weights["1", "3"] <- 0
#   expected <- reference_flows(sparse_weights)
#
#   result <- run_doubly(shuffled[!(from_id == "1" & to_id == "3")])
#   expect_equal(
#     result$flow,
#     expected[cbind(result$from_id, result$to_id)],
#     tolerance = 1e-6
#   )
#   expect_identical(result[from_id == "1" & to_id == "3"]$flow, 0)
# })
#
# test_that("doubly-constrained: errors when totals don't match", {
#   # the missing id counts as 0, so the totals no longer match. the validators
#   # also warn about the missing id
#
#   expect_error(
#     suppressWarnings(constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = make_tm_3x3(),
#       land_use_data = make_lu_match20()[1:2],
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE
#     )),
#     regexp = "sum[[:space:]]+of[[:space:]]+origins[[:space:]]+must"
#   )
# })
#
# test_that("doubly-constrained: NA values and missing ids count as 0", {
#   # id "4" is in travel_matrix but has NA demand and supply (or is missing from
#   # land_use_data). it counts as 0, so it gets no flows and the flows between
#   # the other ids are the same as without it
#
#   tm_4 <- data.table::data.table(
#     expand.grid(from_id = c("1", "2", "3", "4"), to_id = c("1", "2", "3", "4"))
#   )
#   tm_4[, travel_time := 10 + 5 * abs(as.integer(from_id) - as.integer(to_id))]
#   tm_3 <- tm_4[from_id != "4" & to_id != "4"]
#
#   lu_na <- rbind(
#     make_lu_match20(),
#     data.table::data.table(id = "4", population = NA, jobs = NA)
#   )
#
#   run <- function(tm, lu) {
#     suppressWarnings(constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = tm,
#       land_use_data = lu,
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE
#     ))
#   }
#
#   expected <- run(tm_3, make_lu_match20())
#
#   for (lu in list(lu_na, make_lu_match20())) {
#     result <- run(tm_4, lu)
#
#     expect_identical(result[from_id == "4" | to_id == "4"]$flow, rep(0, 7))
#     expect_equal(
#       result[from_id != "4" & to_id != "4"]$flow,
#       expected$flow,
#       tolerance = 1e-6
#     )
#   }
# })
#
# test_that("doubly-constrained: errors when total demand and supply are 0", {
#   lu_zero <- make_lu_match20()[, `:=`(population = NA, jobs = 0)]
#
#   expect_error(
#     suppressWarnings(constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = make_tm_3x3(),
#       land_use_data = lu_zero,
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE
#     )),
#     regexp = "total[[:space:]]+demand[[:space:]]+and[[:space:]]+supply"
#   )
# })
#
# test_that("doubly-constrained: converges with very small impedance weights", {
#   tm <- make_tm_3x3()
#   tm[, travel_time := travel_time + 60]
#   lu <- make_lu_match20()
#
#   # exp(-0.5 * c) is ~1e-13 to 1e-19 here
#
#   result <- expect_silent(
#     constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = tm,
#       land_use_data = lu,
#       travel_cost = "travel_time",
#       decay_function = decay_exponential(decay_value = 0.5),
#       demand = "population",
#       supply = "jobs",
#       detailed_results = TRUE
#     )
#   )
#
#   by_origin <- result[, .(flow = sum(flow)), by = from_id]
#   by_destination <- result[, .(flow = sum(flow)), by = to_id]
#   expect_equal(
#     by_origin$flow,
#     lu$population[match(by_origin$from_id, lu$id)],
#     tolerance = 1e-3
#   )
#   expect_equal(
#     by_destination$flow,
#     lu$jobs[match(by_destination$to_id, lu$id)],
#     tolerance = 1e-3
#   )
# })
#
# test_that("doubly-constrained: warns when balancing doesn't converge", {
#   expect_warning(
#     constrained_accessibility(
#       constraint = "doubly",
#       travel_matrix = make_tm_3x3(),
#       land_use_data = make_lu_match20(),
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       max_iterations = 1,
#       detailed_results = TRUE
#     ),
#     regexp = "did not converge"
#   )
# })
#
# test_that("fill_missing_ids fills missing combinations when using group_by", {
#   tm <- make_tm_3x3()
#   lu <- make_lu_match20()
#
#   # bus doesn't serve origin 3, so the (3, bus) combination is missing
#
#   tm_modes <- data.table::rbindlist(
#     list(car = tm, bus = tm[from_id != "3"]),
#     idcol = "mode"
#   )
#
#   run <- function(constraint, travel_matrix, group_by = "mode") {
#     constrained_accessibility(
#       constraint = constraint,
#       travel_matrix = travel_matrix,
#       land_use_data = lu,
#       travel_cost = "travel_time",
#       decay_function = exp_decay_01,
#       demand = "population",
#       supply = "jobs",
#       active = TRUE,
#       group_by = group_by
#     )
#   }
#
#   for (constraint in c("total", "singly")) {
#     result <- run(constraint, tm_modes)
#     expect_identical(nrow(result), 6L)
#     expect_identical(result[from_id == "3" & mode == "bus"]$supply, 0)
#   }
#
#   # singly-constrained car results don't depend on the bus rows
#
#   result <- run("singly", tm_modes)
#   ungrouped <- run("singly", tm, group_by = character(0))
#   car <- result[mode == "car"]
#   expect_equal(
#     car$supply,
#     ungrouped$supply[match(car$from_id, ungrouped$from_id)]
#   )
# })
#
# test_that("total-constrained: doesn't add an index to land_use_data", {
#   lu <- make_lu_large()
#
#   # data.table auto-indexing is only triggered with character ids
#
#   tm <- make_tm_3x3()
#   tm[, `:=`(from_id = as.character(from_id), to_id = as.character(to_id))]
#
#   constrained_accessibility(
#     travel_matrix = tm,
#     land_use_data = lu,
#     travel_cost = "travel_time",
#     supply = "jobs",
#     demand = "population",
#     constraint = "total",
#     decay_function = exp_decay_01,
#     active = TRUE
#   )
#
#   expect_true(is.null(attr(lu, "index")))
# })
