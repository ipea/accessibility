# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(
  travel_matrix = smaller_matrix,
  land_use_data = get("land_use_data", envir = parent.frame()),
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population",
  decay_function = decay_exponential(0.1),
  alpha = 1,
  group_by = "mode",
  fill_missing_ids = TRUE,
  detailed_results = FALSE
) {
  spatial_availability(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    demand,
    decay_function,
    alpha,
    group_by,
    fill_missing_ids,
    detailed_results
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(alpha = "a"))
  expect_error(tester(alpha = -1))
  expect_error(tester(alpha = c(1, 2)))
  expect_error(tester(alpha = Inf))

  expect_error(tester(decay_function = "a"))
  expect_error(tester(decay_function = mean))
  expect_error(tester(decay_function = get))

  expect_error(tester(opportunity = 1))
  expect_error(tester(opportunity = c("schools", "jobs")))

  expect_error(tester(travel_cost = 1))
  expect_error(tester(travel_cost = c("travel_time", "monetary_cost")))

  expect_error(tester(demand = 1))
  expect_error(tester(demand = c("population", "population")))

  expect_error(tester(group_by = 1))
  expect_error(tester(group_by = NA))
  expect_error(tester(group_by = "from_id"))
  expect_error(tester(group_by = c("mode", "mode")))

  expect_error(tester(fill_missing_ids = 1))
  expect_error(tester(fill_missing_ids = c(TRUE, TRUE)))
  expect_error(tester(fill_missing_ids = NA))

  expect_error(tester(detailed_results = 1))
  expect_error(tester(detailed_results = c(TRUE, TRUE)))
  expect_error(tester(detailed_results = NA))

  expect_error(tester(as.list(travel_matrix)))
  expect_error(tester(travel_matrix[, .(oi = from_id, to_id, travel_time)]))
  expect_error(tester(travel_matrix[, .(from_id, oi = to_id, travel_time)]))
  expect_error(
    tester(
      travel_matrix[, .(from_id, to_id, oi = travel_time)],
      travel_cost = "travel_time"
    )
  )
  expect_error(
    tester(
      travel_matrix[, .(from_id, to_id, travel_time, oi = mode)],
      group_by = "mode"
    )
  )

  expect_error(tester(as.list(land_use_data)))
  expect_error(
    tester(land_use_data = land_use_data[, .(oi = id, jobs, population)])
  )
  expect_error(
    tester(
      land_use_data = land_use_data[, .(id, oi = jobs, population)],
      opportunity = "jobs"
    )
  )
  expect_error(
    tester(
      land_use_data = land_use_data[, .(id, jobs, oi = population)],
      demand = "population"
    )
  )
})

test_that("throws warning if travel_matrix has extra col", {
  # i.e. col not listed in travel_cost and by_col
  expect_warning(tester(group_by = character(0)))
})

test_that("returns a dataframe whose class is the same as travel_matrix's", {
  result <- tester()
  expect_is(result, "data.table")
  result <- tester(land_use_data = as.data.frame(land_use_data))
  expect_is(result, "data.table")

  result <- tester(as.data.frame(smaller_matrix))
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")
  result <- tester(as.data.frame(smaller_matrix), as.data.frame(land_use_data))
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")
})

test_that("result has correct structure", {
  result <- tester()
  expect_true(ncol(result) == 3)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$jobs, "numeric")

  result <- tester(opportunity = "schools")
  expect_true(ncol(result) == 3)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$schools, "numeric")

  suppressWarnings(result <- tester(group_by = character(0)))
  expect_true(ncol(result) == 2)
  expect_is(result$id, "character")
  expect_is(result$jobs, "numeric")

  result <- tester(
    data.table::data.table(
      mode = character(),
      from_id = character(),
      to_id = character(),
      travel_time = integer()
    )
  )
  expect_true(ncol(result) == 3)
  expect_true(nrow(result) == 0)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$jobs, "numeric")
})

test_that("input data sets remain unchanged", {
  original_smaller_matrix <- travel_matrix[1:10]
  original_land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

  result <- tester()

  # subsets in other functions tests set smaller_matrix index
  data.table::setindex(smaller_matrix, NULL)

  expect_equal(original_smaller_matrix, smaller_matrix)
  expect_equal(original_land_use_data, land_use_data)
})

test_that("fill_missing_ids arg works correctly", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff")
  ]
  small_travel_matrix <- small_travel_matrix[
    !(from_id == "89a88cdb57bffff" & mode == "transit2")
  ]

  result <- tester(small_travel_matrix, fill_missing_ids = TRUE)
  result[, jobs := as.integer(jobs)]
  data.table::setkey(result, NULL)
  expect_identical(
    result,
    data.table::data.table(
      id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), each = 2),
      mode = rep(c("transit", "transit2"), times = 2),
      jobs = c(362330L, 0L, 133722L, 496053L)
    )
  )

  result <- tester(small_travel_matrix, fill_missing_ids = FALSE)
  result[, jobs := as.integer(jobs)]
  expect_identical(
    result,
    data.table::data.table(
      id = c("89a88cdb57bffff", "89a88cdb597ffff", "89a88cdb597ffff"),
      mode = c("transit", "transit", "transit2"),
      jobs = c(362330L, 133722L, 496053L)
    )
  )
})

test_that("accepts custom decay function", {
  selected_ids <- c(
    "89a88cdb57bffff",
    "89a88cdb597ffff",
    "89a88cdb5b3ffff",
    "89a88cdb5cfffff",
    "89a88cd909bffff"
  )
  smaller_travel_matrix <- travel_matrix[
    from_id %in% selected_ids & to_id %in% selected_ids
  ]

  custom_function <- function(travel_cost) rep(1L, length(travel_cost))

  result <- tester(smaller_travel_matrix, decay_function = custom_function)
  result[, jobs := round(jobs, digits = 0)]
  expect_identical(
    result,
    data.table::data.table(
      id = rep(selected_ids, 2),
      mode = rep(c("transit", "transit2"), each = 5),
      jobs = rep(c(94, 44, 218, 243, 0))
    )
  )
})

test_that("works even if smaller_matrix and land_use has specific colnames", {
  expected_result <- tester()

  smaller_matrix[, opportunity := "oi"]
  result <- suppressWarnings(tester(smaller_matrix))
  expect_identical(expected_result, result)

  smaller_matrix[, opportunity := NULL]
  smaller_matrix[, travel_cost := "oi"]
  result <- suppressWarnings(tester(smaller_matrix))
  expect_identical(expected_result, result)

  smaller_matrix[, travel_cost := NULL]
  smaller_matrix[, groups := "oi"]
  result <- suppressWarnings(tester(smaller_matrix))
  expect_identical(expected_result, result)

  smaller_matrix[, groups := NULL]
  smaller_matrix[, demand := "oi"]
  result <- suppressWarnings(tester(smaller_matrix))
  expect_identical(expected_result, result)

  smaller_matrix[, demand := NULL]
  land_use_data[, opportunity := "oi"]
  result <- suppressWarnings(tester(land_use_data = land_use_data))
  expect_identical(expected_result, result)

  land_use_data[, opportunity := NULL]
  land_use_data[, demand := "oi"]
  result <- suppressWarnings(tester(land_use_data = land_use_data))
  expect_identical(expected_result, result)

  land_use_data[, demand := NULL]
})

test_that("calculates spatial availability correctly", {
  # data used in Soukhov et al. (2023), slightly modified

  paper_travel_matrix <- data.table::data.table(
    from_id = rep(c("A", "B", "C"), each = 3),
    to_id = as.character(rep(1:3, 3)),
    travel_time = c(15, 30, 100, 30, 15, 100, 100, 100, 15)
  )
  paper_land_use_data <- data.table::data.table(
    id = c("A", "B", "C", "1", "2", "3"),
    population = c(50000, 150000, 10000, 0, 0, 0),
    jobs = c(0, 0, 0, 100000, 100000, 10000)
  )

  result <- tester(
    paper_travel_matrix,
    paper_land_use_data,
    group_by = character(0)
  )
  result[, jobs := round(jobs, digits = 0)]

  expect_identical(
    result,
    data.table::data.table(
      id = c("A", "B", "C"),
      jobs = c(66833, 133203, 9963)
    )
  )
})

test_that("doesn't return NaN when a destination has null denominators", {
  toy_matrix <- data.table::data.table(
    from_id = rep(c("a", "b", "c"), each = 3),
    to_id = rep(c("a", "b", "c"), 3),
    travel_time = c(0, 10, 20, 10, 0, 30, 20, 30, 0)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10, 20, 30),
    population = c(10, 5, 1)
  )

  # no one reaches c, so its 30 jobs are not allocated. a and b split the jobs
  # in a and b proportionally to their population (10:5)

  unreachable_matrix <- data.table::copy(toy_matrix)
  unreachable_matrix[from_id == "c" & to_id == "c", travel_time := 25]

  result <- tester(
    unreachable_matrix,
    toy_land_use,
    decay_function = decay_binary(15),
    group_by = character(0)
  )
  expect_equal(result$jobs, c(20, 10, 0))

  # b is only reached by itself, and it has no population, so its 20 jobs are
  # not allocated. a and c only reach themselves

  no_demand_land_use <- data.table::copy(toy_land_use)
  no_demand_land_use[id == "b", population := 0]

  result <- tester(
    toy_matrix,
    no_demand_land_use,
    decay_function = decay_binary(5),
    group_by = character(0)
  )
  expect_equal(result$jobs, c(10, 0, 30))

  result <- tester(
    unreachable_matrix,
    toy_land_use,
    decay_function = decay_binary(15),
    group_by = character(0),
    detailed_results = TRUE
  )
  expect_false(anyNA(result$jobs))
})

test_that("NA demand in ids not in travel_matrix doesn't affect results", {
  toy_matrix <- data.table::data.table(
    from_id = rep(c("a", "b", "c"), each = 3),
    to_id = rep(c("a", "b", "c"), 3),
    travel_time = c(0, 10, 20, 10, 0, 30, 20, 30, 0)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10, 20, 30),
    population = c(10, 5, 1)
  )
  extra_land_use <- rbind(
    toy_land_use,
    data.table::data.table(id = "z", jobs = 5, population = NA)
  )

  expected <- tester(toy_matrix, toy_land_use, group_by = character(0))
  result <- suppressWarnings(
    tester(toy_matrix, extra_land_use, group_by = character(0))
  )
  expect_false(anyNA(result$jobs))
  expect_equal(result, expected)
})

test_that("results are grouped by decay_function_arg when needed", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff") &
      mode != "transit2"
  ]

  result <- tester(
    small_travel_matrix,
    decay_function = decay_exponential(c(0.5, 0.6))
  )
  result[, jobs := round(jobs, 1)]

  expect_identical(
    result,
    data.table::data.table(
      id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), times = 2),
      mode = rep("transit", 4),
      decay_function_arg = rep(c(0.5, 0.6), each = 2),
      jobs = c(388780.8, 107272.2, 389238.9, 106814.1)
    )
  )
})

test_that("throws warning w/ fill_missing_ids = FALSE with detailed_results", {
  expect_warning(tester(fill_missing_ids = FALSE, detailed_results = TRUE))
})

test_that("result has correct structure with detailed_results = TRUE", {
  result <- tester(detailed_results = TRUE)
  expect_true(ncol(result) == 7)
  expect_is(result$mode, "character")
  expect_is(result$from_id, "character")
  expect_is(result$to_id, "character")
  expect_is(result$demand_bal_fac, "numeric")
  expect_is(result$impedance_bal_fac, "numeric")
  expect_is(result$combined_bal_fac, "numeric")
  expect_is(result$jobs, "numeric")

  result <- tester(detailed_results = TRUE, opportunity = "schools")
  expect_true(ncol(result) == 7)
  expect_is(result$mode, "character")
  expect_is(result$from_id, "character")
  expect_is(result$to_id, "character")
  expect_is(result$demand_bal_fac, "numeric")
  expect_is(result$impedance_bal_fac, "numeric")
  expect_is(result$combined_bal_fac, "numeric")
  expect_is(result$schools, "numeric")

  result <- tester(smaller_matrix[0], detailed_results = TRUE)
  expect_true(ncol(result) == 7)
  expect_true(nrow(result) == 0)
  expect_is(result$mode, "character")
  expect_is(result$from_id, "character")
  expect_is(result$to_id, "character")
  expect_is(result$demand_bal_fac, "numeric")
  expect_is(result$impedance_bal_fac, "numeric")
  expect_is(result$combined_bal_fac, "numeric")
  expect_is(result$jobs, "numeric")
})
