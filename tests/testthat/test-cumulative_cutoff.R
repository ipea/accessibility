# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(travel_matrix = smaller_matrix,
                   land_use_data = get("land_use_data", envir = parent.frame()),
                   opportunity = "jobs",
                   travel_cost = "travel_time",
                   cutoff = 30,
                   group_by = "mode",
                   active = TRUE,
                   fill_missing_ids = TRUE) {
  cumulative_cutoff(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    cutoff,
    group_by,
    active,
    fill_missing_ids
  )
}

tester_with_cost <- function(travel_matrix = small_frontier,
                             travel_cost = c("travel_time", "monetary_cost"),
                             cutoff = list(30, 10),
                             ...) {
  tester(travel_matrix, travel_cost = travel_cost, cutoff = cutoff, ...)
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(opportunity = 1))
  expect_error(tester(opportunity = c("schools", "jobs")))

  expect_error(tester(travel_cost = 1))
  expect_error(tester(travel_cost = NA_character_))
  expect_error(tester(travel_cost = character()))
  expect_error(tester(travel_cost = c("travel_time", "travel_time")))

  expect_error(tester(cutoff = "banana"))
  expect_error(tester(cutoff = -3))
  expect_error(tester(cutoff = Inf))
  expect_error(tester(cutoff = NA_real_))
  expect_error(tester(cutoff = numeric(0)))
  expect_error(tester(cutoff = c(1, 1)))
  expect_error(tester_with_cost(cutoff = 3))
  expect_error(tester_with_cost(cutoff = list(3)))
  expect_error(tester_with_cost(cutoff = list(3, "a")))
  expect_error(tester_with_cost(cutoff = list(3, -3)))
  expect_error(tester_with_cost(cutoff = list(3, Inf)))
  expect_error(tester_with_cost(cutoff = list(3, NA_real_)))
  expect_error(tester_with_cost(cutoff = list(3, numeric())))
  expect_error(tester_with_cost(cutoff = list(3, c(1, 1))))

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
  expect_is(result$jobs, "numeric")

  result <- tester(opportunity = "schools")
  expect_true(ncol(result) == 3)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$schools, "numeric")

  result <- tester(cutoff = c(15, 30))
  expect_true(ncol(result) == 4)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$travel_time, "numeric")
  expect_is(result$jobs, "numeric")

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

  result <- tester(
    data.table::data.table(
      mode = character(),
      from_id = character(),
      to_id = character(),
      travel_time = integer()
    ),
    cutoff = c(15, 30)
  )
  expect_true(ncol(result) == 4)
  expect_true(nrow(result) == 0)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$travel_time, "numeric")
  expect_is(result$jobs, "numeric")

  result <- tester_with_cost()
  expect_true(ncol(result) == 5)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$travel_time, "numeric")
  expect_is(result$monetary_cost, "numeric")
  expect_is(result$jobs, "numeric")

  suppressWarnings(result <- tester_with_cost(group_by = character()))
  expect_true(ncol(result) == 4)
  expect_is(result$id, "character")
  expect_is(result$travel_time, "numeric")
  expect_is(result$monetary_cost, "numeric")
  expect_is(result$jobs, "numeric")

  result <- tester_with_cost(small_frontier[0])
  expect_true(ncol(result) == 5)
  expect_is(result$id, "character")
  expect_is(result$mode, "character")
  expect_is(result$travel_time, "numeric")
  expect_is(result$monetary_cost, "numeric")
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
  selected_ids <- c(
    "89a88cd909bffff",
    "89a88cdb57bffff",
    "89a88cdb597ffff",
    "89a88cdb5b3ffff",
    "89a88cdb5cfffff"
  )
  smaller_travel_matrix <- travel_matrix[
    from_id %in% selected_ids & to_id %in% selected_ids
  ]

  result <- tester(smaller_travel_matrix, group_by = "mode")
  expected_result <- data.table::data.table(
    id = rep(selected_ids, each = 2),
    mode = rep(c("transit", "transit2"), 5),
    jobs = rep(as.numeric(c(0, 82, 408, 408, 109)), each = 2)
  )
  expect_identical(result, expected_result)

  result <- tester(
    smaller_travel_matrix,
    cutoff = 45,
    opportunity = "population",
    active = FALSE
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, each = 2),
    mode = rep(c("transit", "transit2"), 5),
    population = rep(as.numeric(c(0, 5404, 4552, 2363, 4552)), each = 2)
  )
  expect_identical(result, expected_result)

  # when the provided matrix/frontier includes more than 1 trip per od pair -
  # i.e. not double counting opportunities when more than 1 trip can be used
  # between origins and destinations

  test_frontier <- pareto_frontier[
    from_id %in% selected_ids & to_id %in% selected_ids
  ]

  result <- tester_with_cost(test_frontier, cutoff = list(120, c(5, 15)))
  expected_result <- data.table::data.table(
    id = rep(selected_ids, each = 4),
    mode = rep(rep(c("transit", "transit2"), each = 2), times = 5),
    travel_time = 120,
    monetary_cost = rep(c(5, 15), 10),
    jobs = rep(as.numeric(c(499, 599, 499, 599, rep(599, 16))))
  )
  expect_identical(result, expected_result)

  result <- tester_with_cost(
    test_frontier,
    cutoff = list(120, c(5, 15)),
    opportunity = "population",
    active = FALSE
  )
  expected_result <- data.table::data.table(
    id = rep(selected_ids, each = 4),
    mode = rep(rep(c("transit", "transit2"), each = 2), times = 5),
    travel_time = 120,
    monetary_cost = rep(c(5, 15), 10),
    population = rep(as.numeric(c(3435, 5404, 3435, 5404, rep(5404, 16))))
  )
  expect_identical(result, expected_result)
})

test_that("fill_missing_ids arg works correctly", {
  # with one travel cost and one cutoff

  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff")
  ]
  small_travel_matrix <- small_travel_matrix[
    from_id != "89a88cdb57bffff" | travel_time > 40
  ]

  result <- tester(small_travel_matrix)
  data.table::setkey(result, NULL)
  expect_identical(
    result,
    data.table::data.table(
      id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), each = 2),
      mode = rep(c("transit", "transit2"), times = 2),
      jobs = rep(as.numeric(c(0, 36567)), each = 2)
    )
  )

  result <- tester(
    small_travel_matrix,
    land_use_data,
    fill_missing_ids = FALSE
  )
  data.table::setkey(result, NULL)
  expect_identical(
    result,
    data.table::data.table(
      id = rep("89a88cdb597ffff", each = 2),
      mode = c("transit", "transit2"),
      jobs = rep(36567, each = 2)
    )
  )

  # with one travel cost and more than one cutoff

  result <- tester(small_travel_matrix, cutoff = c(15, 50))
  data.table::setkey(result, NULL)
  expected_result <- data.table::data.table(
    id = rep(c("89a88cdb57bffff", "89a88cdb597ffff"), each = 4),
    mode = rep(rep(c("transit", "transit2"), each = 2), times = 2),
    travel_time = rep(c(15, 50), times = 4),
    jobs = as.numeric(c(rep(c(0, 187799), 2), rep(c(3008, 257648), 2)))
  )

  expect_identical(result, expected_result)

  result <- tester(
    small_travel_matrix,
    cutoff = c(15, 50),
    fill_missing_ids = FALSE
  )
  data.table::setkey(result, NULL)

  expect_identical(result, expected_result[jobs != 0])

  # with more than one travel cost

  test_frontier <- rbind(small_frontier, small_frontier[1])
  test_frontier[11, mode := "transit2"]
  test_frontier[11, travel_time := 100]

  result <- tester_with_cost(test_frontier, cutoff = list(10, 10))
  expected_result <- data.table::data.table(
    id = "89a881a5a2bffff",
    mode = c("transit", "transit2"),
    travel_time = 10,
    monetary_cost = 10,
    jobs = as.numeric(c(323, 0))
  )
  data.table::setkey(result, NULL)
  expect_identical(result, expected_result)

  result <- tester_with_cost(
    test_frontier,
    cutoff = list(10, 10),
    fill_missing_ids = FALSE
  )
  expect_identical(result, expected_result[1])
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

test_that("works with cutoffs with floating point noise and any colname", {
  toy_matrix <- data.table::data.table(
    from_id = c(rep(c("a", "b", "c"), each = 3), "d"),
    to_id = c(rep(c("a", "b", "c"), 3), "a"),
    fare = c(0, 0.2, 0.3, 0.2, 0, 0.4, 0.3, 0.4, 0, 1)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c", "d"),
    jobs = c(10, 20, 30, 40)
  )

  # seq() cutoffs are not exactly 0.1, 0.2, ... (e.g. the 4th is
  # 0.30000000000000004). d doesn't reach anyone, so missing ids are filled

  result <- tester(
    toy_matrix,
    toy_land_use,
    travel_cost = "fare",
    cutoff = seq(0, 0.5, by = 0.1),
    group_by = character(0)
  )
  expect_identical(result[id == "a"]$jobs, c(10, 10, 30, 60, 60, 60))
  expect_identical(result[id == "d"]$jobs, rep(0, 6))

  data.table::setnames(toy_matrix, "fare", "bus fare")
  result <- tester(
    toy_matrix,
    toy_land_use,
    travel_cost = "bus fare",
    cutoff = 0.3,
    group_by = character(0)
  )
  expect_identical(result$jobs, c(60, 30, 40, 0))
})

test_that("raises a clear error if id types are incompatible", {
  int_matrix <- data.table::data.table(
    from_id = 1:2,
    to_id = 1:2,
    travel_time = c(1, 2)
  )
  chr_land_use <- data.table::data.table(id = c("1", "2"), jobs = c(1, 2))

  expect_error(
    tester(int_matrix, chr_land_use, cutoff = 5, group_by = character(0)),
    regexp = "compatible[[:space:]]+types"
  )

  # integer vs double and factor vs character ids join fine, so no error

  dbl_land_use <- data.table::data.table(id = c(1, 2), jobs = c(1, 2))
  expect_error(
    tester(int_matrix, dbl_land_use, cutoff = 5, group_by = character(0)),
    NA
  )

  chr_matrix <- data.table::data.table(
    from_id = c("1", "2"),
    to_id = c("1", "2"),
    travel_time = c(1, 2)
  )
  fct_land_use <- data.table::data.table(
    id = factor(c("1", "2")),
    jobs = c(1, 2)
  )
  expect_error(
    tester(chr_matrix, fct_land_use, cutoff = 5, group_by = character(0)),
    NA
  )
})

test_that("result is not keyed, even when missing ids are filled", {
  toy_matrix <- data.table::data.table(
    from_id = c("a", "a", "b"),
    to_id = c("a", "b", "a"),
    travel_time = c(0, 10, 50)
  )
  toy_land_use <- data.table::data.table(id = c("a", "b"), jobs = c(10, 20))

  # b reaches nothing within 30 minutes, so it's filled with 0

  result <- tester(
    toy_matrix,
    toy_land_use,
    cutoff = 30,
    group_by = character(0)
  )
  expect_identical(result$jobs, c(30, 0))
  expect_null(data.table::key(result))

  for (fill in c(TRUE, FALSE)) {
    result <- tester(
      as.data.frame(toy_matrix),
      toy_land_use,
      cutoff = c(30, 60),
      group_by = character(0),
      fill_missing_ids = fill
    )
    expect_null(attr(result, "sorted"))
  }
})

test_that("edge cases of cutoffs and travel costs are handled", {
  # costs equal to infinity or NA are never reached. b reaches a destination
  # within 30 minutes, but it has no opportunities. c reaches nothing

  toy_matrix <- data.table::data.table(
    from_id = c("a", "a", "a", "a", "b", "b", "c"),
    to_id = c("a", "b", "c", "d", "b", "a", "a"),
    travel_time = c(0, 30, NA, Inf, 0, 45, 100)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c", "d"),
    jobs = c(10, 0, 7, 5)
  )

  result <- tester(
    toy_matrix,
    toy_land_use,
    cutoff = c(60, 30),
    group_by = character(0),
    fill_missing_ids = FALSE
  )
  expect_identical(result$id, c("a", "a", "b", "b"))
  expect_identical(result$travel_time, c(30, 60, 30, 60))
  expect_identical(result$jobs, c(10, 10, 0, 10))

  result <- tester(
    toy_matrix,
    toy_land_use,
    cutoff = c(60, 30),
    group_by = character(0)
  )
  expect_identical(result$id, c("a", "a", "b", "b", "c", "c"))
  expect_identical(result$jobs, c(10, 10, 0, 10, 0, 0))
})

test_that("large integer sums don't overflow", {
  # a reaches 10 jobs and b reaches more jobs than the largest integer, which
  # used to raise an error when sums of different ids had different types

  toy_matrix <- data.table::data.table(
    from_id = c("a", "b", "b"),
    to_id = c("a", "a", "b"),
    travel_time = c(0, 0, 20)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b"),
    jobs = c(10L, .Machine$integer.max)
  )

  result <- tester(
    toy_matrix,
    toy_land_use,
    cutoff = c(30, 60),
    group_by = character(0),
    fill_missing_ids = FALSE
  )
  expect_identical(result$jobs, c(10, 10, rep(.Machine$integer.max + 10, 2)))

  result <- tester(
    toy_matrix,
    toy_land_use,
    cutoff = 30,
    group_by = character(0),
    fill_missing_ids = FALSE
  )
  expect_identical(result$jobs, c(10, .Machine$integer.max + 10))
})
