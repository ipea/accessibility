# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(travel_matrix = smaller_matrix,
                   land_use_data = get("land_use_data", envir = parent.frame()),
                   opportunity = "jobs",
                   travel_cost = "travel_time",
                   interval = c(10, 30),
                   interval_increment = 1,
                   summary_function = stats::median,
                   group_by = "mode",
                   active = TRUE,
                   fill_missing_ids = TRUE) {
  cumulative_interval(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    interval,
    interval_increment,
    summary_function,
    group_by,
    active,
    fill_missing_ids
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(interval = "banana"))

  expect_error(tester(interval = 3))
  expect_error(tester(interval = c(-1, 10)))
  expect_error(tester(interval = c(11, 10)))
  expect_error(tester(interval = c(10, 10)))
  expect_error(tester(interval = c(1, Inf)))
  expect_error(tester(interval = c(1, NA)))

  expect_error(tester(interval = list("a")))
  expect_error(tester(interval = list()))
  expect_error(tester(interval = list(c(10, 20), c(10, 20))))
  expect_error(tester(interval = list(3)))
  expect_error(tester(interval = list(c(-1, 10))))
  expect_error(tester(interval = list(c(11, 10))))
  expect_error(tester(interval = list(c(10, 10))))
  expect_error(tester(interval = list(c(1, Inf))))
  expect_error(tester(interval = list(c(1, NA))))

  expect_error(tester(interval_increment = "a"))
  expect_error(tester(interval_increment = Inf))
  expect_error(tester(interval_increment = c(1, 1)))
  expect_error(tester(interval_increment = -1))

  expect_error(tester(summary_function = "test"))
  expect_error(tester(summary_function = readRDS))
  expect_error(tester(summary_function = identity))

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
  expect_is(result$jobs, "integer")

  result <- tester(opportunity = "schools")
  expect_true(ncol(result) == 3)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$schools, "integer")

  suppressWarnings(result <- tester(group_by = character(0)))
  expect_true(ncol(result) == 2)
  expect_is(result$id, "character")
  expect_is(result$jobs, "integer")

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
  expect_is(result$jobs, "integer")

  result <- tester(interval = list(c(10, 30), c(20, 30)))
  expect_true(ncol(result) == 4)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$interval, "character")
  expect_is(result$jobs, "integer")
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

  result <- tester(
    smaller_travel_matrix,
    interval = c(40, 45),
    group_by = "mode"
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    jobs = rep(as.integer(c(82, 517, 517, 304, 0)), 2)
  )
  expect_identical(result, expected_result)

  result <- tester(
    smaller_travel_matrix,
    interval = c(40, 45),
    opportunity = "population",
    group_by = "mode",
    active = FALSE
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    population = rep(as.integer(c(1946, 3457, 2363, 4552, 0)), 2)
  )
  expect_identical(result, expected_result)

  # with more than one interval

  result <- tester(
    smaller_travel_matrix,
    interval = list(c(40, 45), c(40, 50)),
    group_by = "mode"
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 4),
    mode = rep(rep(c("transit", "transit2"), each = 5), 2),
    interval = rep(c("[40,45]", "[40,50]"), each = 10),
    jobs = c(
      rep(as.integer(c(82, 517, 517, 304, 0)), 2),
      rep(as.integer(c(82, 599, 599, 499, 0)), 2)
    )
  )
  expect_identical(result, expected_result)

  result <- tester(
    smaller_travel_matrix,
    interval = list(c(40, 45), c(40, 50)),
    opportunity = "population",
    group_by = "mode",
    active = FALSE
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 4),
    mode = rep(rep(c("transit", "transit2"), each = 5), 2),
    interval = rep(c("[40,45]", "[40,50]"), each = 10),
    population = c(
      rep(as.integer(c(1946, 3457, 2363, 4552, 0)), 2),
      rep(as.integer(c(5404, 4552, 2363, 4552, 0)), 2)
    )
  )
  expect_identical(result, expected_result)
})

test_that("summarizes the result according to summary function", {
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

  result <- tester(
    smaller_travel_matrix,
    interval = c(40, 45),
    summary_function = min,
    group_by = "mode"
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    jobs = rep(as.integer(c(82, 408, 408, 109, 0)), 2)
  )
  expect_identical(result, expected_result)

  result <- tester(
    smaller_travel_matrix,
    interval = c(40, 45),
    summary_function = mean,
    group_by = "mode"
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    jobs = rep(as.integer(c(82, 512, 508, 304, 0)), 2)
  )
  expect_identical(result, expected_result)
})

test_that("accessibility is correctly calculated when ids are missing", {
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

  result <- tester(
    smaller_travel_matrix,
    interval = c(5, 6),
    summary_function = min,
    group_by = "mode"
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids[order(selected_ids)], each = 2),
    mode = rep(c("transit", "transit2"), 5),
    jobs = rep(as.integer(c(0, 0, 0, 0, 0)), 2)
  )
  expect_identical(result, expected_result)
})

test_that("interval_increment arg is being used", {
  # hard to "perfectly" assess if the interval_increment value is being applied
  # correctly, but the code is trivial enough to let us say that it's correctly
  # applied if the results are different when using different increments

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

  result_increment_1 <- tester(
    smaller_travel_matrix,
    interval_increment = 1,
    interval = c(5, 7)
  )
  result_increment_2 <- tester(
    smaller_travel_matrix,
    interval_increment = 2,
    interval = c(5, 7)
  )

  expect_false(identical(result_increment_1, result_increment_2))
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

test_that("each interval is summarised over its own cutoffs only", {
  toy_matrix <- data.table::data.table(
    from_id = rep(c("a", "b", "c"), each = 3),
    to_id = rep(c("a", "b", "c"), 3),
    travel_time = c(0, 10, 20, 10, 0, 30, 20, 30, 0)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10, 20, 30)
  )

  toy_tester <- function(interval) {
    tester(
      toy_matrix,
      toy_land_use,
      interval = interval,
      interval_increment = 10,
      summary_function = mean,
      group_by = character(0)
    )
  }

  # [0, 20] uses cutoffs 0, 10 and 20 (a: mean(10, 30, 60) = 33.3) and [5, 15]
  # uses 5 and 15 (a: mean(10, 30) = 20), whether requested alone or together

  result <- toy_tester(list(c(0, 20), c(5, 15)))
  expect_identical(result[interval == "[0,20]"]$jobs, c(33L, 26L, 33L))
  expect_identical(result[interval == "[5,15]"]$jobs, c(20L, 25L, 30L))

  expect_identical(
    result[interval == "[0,20]"]$jobs,
    toy_tester(c(0, 20))$jobs
  )
  expect_identical(
    result[interval == "[5,15]"]$jobs,
    toy_tester(c(5, 15))$jobs
  )
})

test_that("fill_missing_ids arg works correctly", {
  toy_matrix <- data.table::data.table(
    from_id = c(rep(c("a", "b", "c"), each = 3), "d"),
    to_id = c(rep(c("a", "b", "c"), 3), "a"),
    travel_time = c(0, 10, 20, 10, 0, 30, 20, 30, 0, 100)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c", "d"),
    jobs = c(10, 20, 30, 40)
  )

  toy_tester <- function(...) {
    tester(
      toy_matrix,
      toy_land_use,
      interval_increment = 10,
      summary_function = mean,
      group_by = character(0),
      ...
    )
  }

  # d doesn't reach any opportunity within the interval

  result <- toy_tester(interval = c(0, 20))
  expect_identical(result$id, c("a", "b", "c", "d"))
  expect_identical(result$jobs, c(33L, 26L, 33L, 0L))

  result <- toy_tester(interval = c(0, 20), fill_missing_ids = FALSE)
  expect_identical(result$id, c("a", "b", "c"))
  expect_identical(result$jobs, c(33L, 26L, 33L))
})

test_that("the upper limit of the interval is always considered", {
  toy_matrix <- data.table::data.table(
    from_id = rep(c("a", "b", "c"), each = 3),
    to_id = rep(c("a", "b", "c"), 3),
    travel_time = c(0, 10, 25, 10, 0, 30, 25, 30, 0)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10, 20, 30)
  )

  # cutoffs are 0, 10, 20 and 25. a reaches 10, 30, 30 and 60 jobs

  result <- tester(
    toy_matrix,
    toy_land_use,
    interval = c(0, 25),
    interval_increment = 10,
    summary_function = mean,
    group_by = character(0)
  )
  expect_identical(result$jobs, c(32L, 27L, 32L))
})
