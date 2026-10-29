# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(
  travel_matrix = smaller_matrix,
  land_use_data = get("land_use_data", envir = parent.frame()),
  opportunity = "jobs",
  travel_cost = "travel_time",
  decay_function = decay_binary(30),
  group_by = "mode",
  active = TRUE,
  fill_missing_ids = TRUE
) {
  gravity(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    decay_function,
    group_by,
    active,
    fill_missing_ids
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(decay_function = "a"))
  expect_error(tester(decay_function = mean))
  expect_error(tester(decay_function = get))

  expect_error(tester(opportunity = 1))
  expect_error(tester(opportunity = c("schools", "jobs")))

  expect_error(tester(travel_cost = 1))
  expect_error(tester(travel_cost = c("travel_time", "monetary_cost")))

  expect_error(tester(group_by = 1))
  expect_error(tester(group_by = NA))
  expect_error(tester(group_by = "from_id"))
  expect_error(tester(group_by = c("mode", "mode")))

  expect_error(tester(active = 1))
  expect_error(tester(active = c(TRUE, TRUE)))
  expect_error(tester(active = NA))

  expect_error(tester(fill_missing_ids = 1))
  expect_error(tester(fill_missing_ids = c(TRUE, TRUE)))
  expect_error(tester(fill_missing_ids = NA))

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
  expect_error(tester(land_use_data = land_use_data[, .(oi = id, jobs)]))
  expect_error(
    tester(
      land_use_data = land_use_data[, .(id, oi = jobs)],
      opportunity = "jobs"
    )
  )
})

test_that("throws warning if travel_matrix extra col", {
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
  result <- tester(
    as.data.frame(smaller_matrix),
    land_use_data = as.data.frame(land_use_data)
  )
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

test_that("active and passive accessibility is correctly calculated", {
  # using decay_binary() should yield exact same results of cumulative_cutoff()
  # active/passive cumulative_cutoff() is tested in its own file
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

  result <- tester(smaller_travel_matrix)
  data.table::setorderv(result, c("id", "mode", "jobs"))

  cum_result <- cumulative_cutoff(
    smaller_travel_matrix,
    land_use_data,
    cutoff = 30,
    opportunity = "jobs",
    travel_cost = "travel_time",
    group_by = "mode"
  )
  expect_identical(result, cum_result)

  result <- tester(smaller_travel_matrix, active = FALSE)
  data.table::setorderv(result, c("id", "mode", "jobs"))

  cum_result <- cumulative_cutoff(
    smaller_travel_matrix,
    land_use_data,
    cutoff = 30,
    opportunity = "jobs",
    travel_cost = "travel_time",
    group_by = "mode",
    active = FALSE
  )
  expect_identical(result, cum_result)
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

  expected_result <- smaller_travel_matrix[
    land_use_data,
    on = c(to_id = "id"),
    jobs := i.jobs
  ]
  expected_result <- expected_result[
    ,
    .(jobs = sum(as.numeric(jobs))),
    by = .(id = from_id, mode)
  ]

  expect_identical(result, expected_result)
})

test_that("fill_missing_ids arg works correctly", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff")
  ]
  small_travel_matrix <- small_travel_matrix[
    !(from_id == "89a88cdb57bffff" & mode == "transit2")
  ]

  result <- tester(
    small_travel_matrix,
    land_use_data,
    fill_missing_ids = TRUE
  )
  data.table::setkey(result, NULL)
  expect_identical(
    result,
    data.table::data.table(
      id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), each = 2),
      mode = rep(c("transit", "transit2"), times = 2),
      jobs = c(22239, 0, 36567, 36567)
    )
  )

  result <- tester(
    small_travel_matrix,
    land_use_data,
    fill_missing_ids = FALSE
  )
  expect_identical(
    result,
    data.table::data.table(
      id = c("89a88cdb57bffff", "89a88cdb597ffff", "89a88cdb597ffff"),
      mode = c("transit", "transit", "transit2"),
      jobs = c(22239, 36567, 36567)
    )
  )
})

test_that("works even if travel_matrix and land_use has specific colnames", {
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
  land_use_data[, opportunity := "oi"]
  result <- suppressWarnings(tester(land_use_data = land_use_data))
  expect_identical(expected_result, result)

  land_use_data[, opportunity := NULL]
})

test_that("results are grouped by decay_function_arg when needed", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff") &
      mode != "transit2"
  ]

  result <- tester(
    small_travel_matrix,
    land_use_data,
    decay_function = decay_exponential(c(0.5, 0.6))
  )
  data.table::setkey(result, NULL)
  result[, jobs := round(jobs, 2)]

  expect_identical(
    result,
    data.table::data.table(
      id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), times = 2),
      mode = rep("transit", 4),
      decay_function_arg = rep(c(0.5, 0.6), each = 2),
      jobs = c(14.11, 28.02, 6.59, 13.4)
    )
  )
})

test_that("decay_fn_arg is char when decay fn is stepped and num otherwise", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff")
  ]

  result <- tester(
    small_travel_matrix,
    decay_function = decay_exponential(c(0.5, 0.6))
  )
  expect_is(result$decay_function_arg, "numeric")

  result <- tester(
    small_travel_matrix,
    decay_function = decay_stepped(
      steps = list(c(10, 20), c(15, 25)),
      weights = list(c(0.5, 0), c(0.5, 0))
    )
  )
  expect_is(result$decay_function_arg, "character")
})

test_that("raises an error if travel_matrix contains negative travel costs", {
  negative_matrix <- data.table::copy(smaller_matrix)
  negative_matrix[1, travel_time := -10]

  expect_error(
    tester(travel_matrix = negative_matrix),
    regexp = "must[[:space:]]+not[[:space:]]+be[[:space:]]+negative"
  )

  # NA costs are still allowed

  na_matrix <- data.table::copy(smaller_matrix)
  na_matrix[1, travel_time := NA]
  expect_error(tester(travel_matrix = na_matrix), NA)
})

test_that("large integer opportunity counts don't overflow or warn", {
  travel_matrix <- data.table::data.table(
    from_id = "a",
    to_id = c("a", "b"),
    travel_time = c(10, 20)
  )
  land_use_data <- data.table::data.table(
    id = c("a", "b"),
    jobs = c(1L, .Machine$integer.max)
  )

  expect_silent(
    result <- gravity(
      travel_matrix,
      land_use_data,
      opportunity = "jobs",
      travel_cost = "travel_time",
      decay_function = decay_binary(30)
    )
  )
  expect_identical(result$jobs, .Machine$integer.max + 1)
})
