# NA values and ids missing from land_use_data count as 0 in every
# accessibility measure. each measure is run with a land_use_data that has NAs
# and misses an id, and with one in which those values are explicitly 0. the
# second one has no NAs and no missing ids, so it never goes through the NA
# replacement. results are calculated with fill_missing_ids = FALSE, because
# filling would turn NA results into 0 and hide the difference

na_travel_matrix <- data.table::data.table(
  from_id = rep(c("a", "b", "c", "d"), each = 4),
  to_id = rep(c("a", "b", "c", "d"), times = 4),
  travel_time = c(0, 10, 20, 30, 10, 0, 15, 25, 20, 15, 0, 10, 30, 25, 10, 0)
)

# "b" has NA jobs, "a" has NA population and "d" is missing

na_land_use_data <- data.table::data.table(
  id = c("a", "b", "c"),
  jobs = c(10, NA, 5),
  population = c(NA, 20, 30)
)

zero_land_use_data <- data.table::data.table(
  id = c("a", "b", "c", "d"),
  jobs = c(10, 0, 5, 0),
  population = c(0, 20, 30, 0)
)

na_calls <- list(
  cumulative_cutoff = function(lu) {
    cumulative_cutoff(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      cutoff = 20,
      fill_missing_ids = FALSE
    )
  },
  cumulative_interval = function(lu) {
    cumulative_interval(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      interval = c(10, 30),
      fill_missing_ids = FALSE
    )
  },
  gravity = function(lu) {
    gravity(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      decay_function = decay_exponential(0.1),
      fill_missing_ids = FALSE
    )
  },
  gravity_passive = function(lu) {
    gravity(
      na_travel_matrix,
      lu,
      "population",
      "travel_time",
      decay_function = decay_exponential(0.1),
      active = FALSE,
      fill_missing_ids = FALSE
    )
  },
  fca_2sfca = function(lu) {
    floating_catchment_area(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      demand = "population",
      method = "2sfca",
      decay_function = decay_exponential(0.1),
      fill_missing_ids = FALSE
    )
  },
  fca_bfca = function(lu) {
    floating_catchment_area(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      demand = "population",
      method = "bfca",
      decay_function = decay_exponential(0.1),
      fill_missing_ids = FALSE
    )
  },
  spatial_availability = function(lu) {
    spatial_availability(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      demand = "population",
      decay_function = decay_exponential(0.1),
      fill_missing_ids = FALSE
    )
  },
  spatial_availability_detailed = function(lu) {
    spatial_availability(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      demand = "population",
      decay_function = decay_exponential(0.1),
      detailed_results = TRUE
    )
  },
  cost_to_closest = function(lu) {
    cost_to_closest(
      na_travel_matrix,
      lu,
      "jobs",
      "travel_time",
      n = c(1, 12),
      fill_missing_ids = FALSE
    )
  },
  total = function(lu) {
    constrained_accessibility(
      na_travel_matrix,
      lu,
      "travel_time",
      supply = "jobs",
      constraint = "total",
      decay_function = decay_exponential(0.1),
      active = TRUE,
      fill_missing_ids = FALSE
    )
  },
  total_detailed = function(lu) {
    constrained_accessibility(
      na_travel_matrix,
      lu,
      "travel_time",
      supply = "jobs",
      constraint = "total",
      decay_function = decay_exponential(0.1),
      active = TRUE,
      detailed_results = TRUE
    )
  },
  singly = function(lu) {
    constrained_accessibility(
      na_travel_matrix,
      lu,
      "travel_time",
      demand = "population",
      supply = "jobs",
      constraint = "singly",
      decay_function = decay_exponential(0.1),
      active = TRUE,
      fill_missing_ids = FALSE
    )
  },
  singly_detailed = function(lu) {
    constrained_accessibility(
      na_travel_matrix,
      lu,
      "travel_time",
      demand = "population",
      supply = "jobs",
      constraint = "singly",
      decay_function = decay_exponential(0.1),
      active = TRUE,
      detailed_results = TRUE
    )
  }
)

test_that("NA values and missing ids in land_use_data count as 0", {
  for (measure in names(na_calls)) {
    with_na <- suppressWarnings(na_calls[[measure]](na_land_use_data))
    with_zero <- na_calls[[measure]](zero_land_use_data)

    expect_equal(with_na, with_zero, info = measure)
    expect_false(anyNA(with_na), info = measure)
  }
})

test_that("warns that NA values and missing ids are treated as 0", {
  expect_warning(
    gravity(
      na_travel_matrix,
      na_land_use_data,
      "jobs",
      "travel_time",
      decay_function = decay_exponential(0.1)
    ),
    "treated as 0"
  )
})
