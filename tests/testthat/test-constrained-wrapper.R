tm <- data.table::data.table(
  expand.grid(
    from_id = c("1", "2"),
    to_id = c("1", "2"),
    stringsAsFactors = FALSE
  )
)
tm[, travel_time := c(10, 20, 15, 10)]

# total demand equals total supply, so the doubly-constrained case also works

lu <- data.table::data.table(
  id = c("1", "2"),
  population = c(5, 7),
  jobs = c(4, 8)
)
decay <- decay_exponential(decay_value = 0.1)

tester <- function(constraint = "total",
                   travel_matrix = tm,
                   land_use_data = lu,
                   travel_cost = "travel_time",
                   demand = "population",
                   supply = "jobs",
                   decay_function = decay,
                   active = TRUE,
                   error_threshold = 0.001,
                   improvement_threshold = 1e-6,
                   max_iterations = 1000,
                   group_by = character(0),
                   fill_missing_ids = TRUE,
                   detailed_results = FALSE) {
  constrained_accessibility(
    travel_matrix = travel_matrix,
    land_use_data = land_use_data,
    travel_cost = travel_cost,
    demand = demand,
    supply = supply,
    constraint = constraint,
    decay_function = decay_function,
    active = active,
    error_threshold = error_threshold,
    improvement_threshold = improvement_threshold,
    max_iterations = max_iterations,
    group_by = group_by,
    fill_missing_ids = fill_missing_ids,
    detailed_results = detailed_results
  )
}

test_that("runs with valid input for every constraint", {
  for (constraint in c("total", "singly")) {
    expect_error(tester(constraint, active = TRUE), NA)
    expect_error(tester(constraint, active = FALSE), NA)
  }

  expect_error(tester("doubly", detailed_results = TRUE), NA)
})

test_that("wrapper argument rules are enforced", {
  # total and singly require active to be TRUE or FALSE

  expect_error(
    tester("total", active = NULL),
    regexp = "active must be TRUE or FALSE"
  )
  expect_error(
    tester("singly", active = NULL),
    regexp = "active must be TRUE or FALSE"
  )

  # active is ignored when constraint = "doubly"

  doubly_result <- tester("doubly", active = NULL, detailed_results = TRUE)
  expect_identical(
    tester("doubly", active = TRUE, detailed_results = TRUE),
    doubly_result
  )
  expect_identical(
    tester("doubly", active = FALSE, detailed_results = TRUE),
    doubly_result
  )
})

test_that("raises errors due to incorrect input", {
  expect_error(tester(constraint = "banana"))

  expect_error(tester(decay_function = "a"))
  expect_error(tester(decay_function = mean))
  expect_error(tester(decay_function = get))

  expect_error(tester(travel_cost = 1))
  expect_error(tester(travel_cost = c("travel_time", "monetary_cost")))

  expect_error(tester(active = FALSE, demand = 1))
  expect_error(tester(active = FALSE, demand = c("population", "population")))
  expect_error(tester(active = FALSE, demand = "banana"))

  expect_error(tester(supply = 1))
  expect_error(tester(supply = c("jobs", "jobs")))
  expect_error(tester(supply = "banana"))

  expect_error(tester(group_by = 1))
  expect_error(tester(group_by = NA))
  expect_error(tester(group_by = "from_id"))
  expect_error(tester(group_by = c("mode", "mode")))

  expect_error(tester(fill_missing_ids = 1))
  expect_error(tester(fill_missing_ids = c(TRUE, TRUE)))
  expect_error(tester(fill_missing_ids = NA))

  expect_error(tester(detailed_results = 1))
  expect_error(tester(detailed_results = NA))

  expect_error(tester("doubly", max_iterations = 0))
  expect_error(tester("doubly", error_threshold = -1))
  expect_error(tester("doubly", improvement_threshold = -1))

  expect_error(tester(travel_matrix = as.list(tm)))
  expect_error(tester(travel_matrix = tm[, .(oi = from_id, to_id, travel_time)]))
  expect_error(tester(travel_matrix = tm[, .(from_id, oi = to_id, travel_time)]))
  expect_error(tester(travel_matrix = tm[, .(from_id, to_id, oi = travel_time)]))
  expect_error(
    tester(
      travel_matrix = tm[, .(from_id, to_id, travel_time, oi = 1)],
      group_by = "mode"
    )
  )

  expect_error(tester(land_use_data = as.list(lu)))
  expect_error(tester(land_use_data = lu[, .(oi = id, jobs, population)]))
  expect_error(tester(land_use_data = lu[, .(id, oi = jobs, population)]))
  expect_error(
    tester(
      land_use_data = lu[, .(id, jobs, oi = population)],
      active = FALSE
    )
  )
})

test_that("raises a clear error if demand or supply has length > 1", {
  expect_error(
    tester(demand = c("population", "population")),
    regexp = "Must have length 1"
  )
  expect_error(
    tester(supply = c("jobs", "jobs")),
    regexp = "Must have length 1"
  )
})
