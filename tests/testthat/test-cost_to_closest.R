# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(
  travel_matrix = smaller_matrix,
  land_use_data = get("land_use_data", envir = parent.frame()),
  opportunity = "schools",
  travel_cost = "travel_time",
  n = 1,
  group_by = "mode",
  active = TRUE,
  fill_missing_ids = TRUE
) {
  cost_to_closest(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    n,
    group_by,
    active,
    fill_missing_ids
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(n = "banana"))
  expect_error(tester(n = -3))
  expect_error(tester(n = Inf))
  expect_error(tester(n = NA))
  expect_error(tester(n = numeric(0)))
  expect_error(tester(n = c(1, 1)))

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

test_that("throws warning if travel_matrix has an extra col", {
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
  expect_is(result$travel_time, "numeric")

  result <- tester(n = c(1, 2))
  expect_true(ncol(result) == 4)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$n, "numeric")
  expect_is(result$travel_time, "numeric")

  suppressWarnings(result <- tester(group_by = character(0)))
  expect_true(ncol(result) == 2)
  expect_is(result$id, "character")
  expect_is(result$travel_time, "numeric")

  result <- tester(
    data.table::data.table(
      mode = character(),
      from_id = character(),
      to_id = character(),
      travel_time = numeric()
    )
  )
  expect_true(ncol(result) == 3)
  expect_true(nrow(result) == 0)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$travel_time, "numeric")

  result <- tester(
    data.table::data.table(
      mode = character(),
      from_id = character(),
      to_id = character(),
      travel_time = numeric()
    ),
    n = c(1, 2)
  )
  expect_true(ncol(result) == 4)
  expect_true(nrow(result) == 0)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$n, "numeric")
  expect_is(result$travel_time, "numeric")
})

test_that("result columns are ordered correctly when length(n)>1", {
  result <- tester(n = c(1, 3))
  expect_identical(names(result), c("id", "mode", "n", "travel_time"))

  result <- tester(n = c(1, 3), fill_missing_ids = FALSE)
  expect_identical(names(result), c("id", "mode", "n", "travel_time"))
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

  result <- tester(smaller_travel_matrix, group_by = "mode")
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    travel_time = rep(c(47, 5.8, 13, 43, 70), 2)
  )
  expect_identical(result, expected_result)

  result <- tester(
    smaller_travel_matrix,
    opportunity = "population",
    group_by = "mode",
    active = FALSE
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, 2),
    mode = rep(c("transit", "transit2"), each = 5),
    travel_time = rep(c(5.8, 5.8, 5.8, 5.8, 58), 2)
  )
  expect_identical(result, expected_result)
})

test_that("output is as expected when ids are missing - n=1", {
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
  smaller_travel_matrix <- rbind(
    smaller_travel_matrix,
    data.table::data.table(
      mode = "transit",
      from_id = "fake_id",
      to_id = "89a88cdb57bffff",
      travel_time = 50
    )
  )

  result <- tester(smaller_travel_matrix, n = 1)
  fake_id_result <- result[id == "fake_id"]
  data.table::setkey(fake_id_result, NULL)
  expected_result <- data.table::data.table(
    id = "fake_id",
    mode = c("transit", "transit2"),
    travel_time = Inf
  )
  expect_identical(fake_id_result, expected_result)

  result <- tester(smaller_travel_matrix, n = 1, fill_missing_ids = FALSE)
  fake_id_result <- result[id == "fake_id"]
  data.table::setkey(fake_id_result, NULL)
  expected_result <- data.table::data.table(
    id = character(0),
    mode = character(0),
    travel_time = numeric(0)
  )
  expect_identical(fake_id_result, expected_result)
})

test_that("output is as expected when ids are missing - n>1", {
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

  result <- tester(smaller_travel_matrix, n = c(1, 3))
  data.table::setkey(result, NULL)
  expected_result_subset <- data.table::data.table(
    id = rep(selected_ids[order(selected_ids)], each = 2),
    mode = rep(c("transit", "transit2"), times = 5),
    n = 3,
    travel_time = Inf
  )
  expect_identical(result[is.infinite(travel_time)], expected_result_subset)

  result <- tester(smaller_travel_matrix, n = c(1, 3), fill_missing_ids = FALSE)
  expected_result_subset <- data.table::data.table(
    id = character(0),
    mode = character(0),
    n = numeric(0),
    travel_time = numeric(0)
  )
  expect_identical(result[is.infinite(travel_time)], expected_result_subset)
})

test_that("output is as expected when ids are missing - length(n)>1", {
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

  result <- tester(smaller_travel_matrix, n = 3)
  data.table::setkey(result, NULL)
  expected_result <- data.table::data.table(
    id = rep(selected_ids[order(selected_ids)], each = 2),
    mode = rep(c("transit", "transit2"), times = 5),
    travel_time = Inf
  )
  expect_identical(result, expected_result)

  result <- tester(smaller_travel_matrix, n = 3, fill_missing_ids = FALSE)
  expected_result <- data.table::data.table(
    id = character(0),
    mode = character(0),
    travel_time = numeric(0)
  )
  expect_identical(result, expected_result)
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

test_that("large integer opportunity counts don't overflow", {
  # the cumulative opportunities at costs 1, 2 and 3 are 1e9, 2e9 and 3e9, so
  # 2.5e9 opportunities are first reached at cost 3

  travel_matrix <- data.table::data.table(
    from_id = "a",
    to_id = c("a", "b", "c"),
    travel_time = c(1, 2, 3)
  )
  land_use_data <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = rep(1000000000L, 3)
  )

  result <- cost_to_closest(
    travel_matrix,
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    n = 2.5e9
  )
  expect_identical(result$travel_time, 3)
})
