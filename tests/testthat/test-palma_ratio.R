# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(accessibility_data = small_access,
                   sociodemographic_data = land_use_data,
                   opportunity = "jobs",
                   population = "population",
                   income = "income_per_capita",
                   group_by = "mode") {
  palma_ratio(
    accessibility_data,
    sociodemographic_data,
    opportunity,
    population,
    income,
    group_by
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(opportunity = 1))
  expect_error(tester(opportunity = c("schools", "jobs")))

  expect_error(tester(population = 1))
  expect_error(tester(population = c("schools", "jobs")))

  expect_error(tester(income = 1))
  expect_error(tester(income = c("schools", "jobs")))

  expect_error(tester(group_by = 1))
  expect_error(tester(group_by = NA))
  expect_error(tester(group_by = "id"))
  expect_error(tester(group_by = c("mode", "mode")))

  expect_error(tester(as.list(small_access)))
  expect_error(tester(small_access[, .(oi = id, jobs, mode)]))
  expect_error(tester(small_access[, .(id, oi = jobs, mode)]))
  expect_error(tester(small_access[, .(id, jobs, oi = mode)]))

  expect_error(tester(sociodemographic_data = as.list(land_use_data)))
  expect_error(
    tester(
      sociodemographic_data = land_use_data[
        ,
        .(oi = id, population, income_per_capita)
      ]
    )
  )
  expect_error(
    tester(
      sociodemographic_data = land_use_data[
        ,
        .(id, oi = population, income_per_capita)
      ]
    )
  )
  expect_error(
    tester(
      sociodemographic_data = land_use_data[
        ,
        .(id, population, oi = income_per_capita)
      ]
    )
  )
})

test_that("throws warning if accessibility_data has an extra col", {
  expect_warning(tester(group_by = character(0)))
})

test_that("returns a dataframe with same class as accessibility_data's", {
  result <- tester()
  expect_is(result, "data.table")
  result <- tester(sociodemographic_data = as.data.frame(land_use_data))
  expect_is(result, "data.table")

  result <- tester(as.data.frame(small_access))
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")
  result <- tester(
    as.data.frame(small_access),
    sociodemographic_data = as.data.frame(land_use_data)
  )
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")
})

test_that("result has correct structure", {
  result <- tester()
  expect_true(ncol(result) == 2)
  expect_is(result$mode, "character")
  expect_is(result$palma_ratio, "numeric")

  suppressWarnings(result <- tester(group_by = character(0)))
  expect_true(ncol(result) == 1)
  expect_is(result$palma_ratio, "numeric")

  result <- tester(
    data.table::data.table(
      mode = character(),
      id = character(),
      jobs = integer()
    )
  )
  expect_true(nrow(result) == 0)
  expect_true(ncol(result) == 2)
  expect_is(result$mode, "character")
  expect_is(result$palma_ratio, "numeric")

  suppressWarnings(
    result <- tester(
      data.table::data.table(
        mode = character(),
        id = character(),
        jobs = integer()
      ),
      group_by = character(0)
    )
  )
  expect_true(nrow(result) == 0)
  expect_true(ncol(result) == 1)
  expect_is(result$palma_ratio, "numeric")
})

test_that("input data sets remain unchanged", {
  original_access_data <- cumulative_cutoff(
    smaller_matrix,
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )
  original_sociodem_data <- readRDS(file.path(data_dir, "land_use_data.rds"))

  result <- tester()

  expect_equal(original_access_data, small_access)
  expect_equal(original_sociodem_data, land_use_data)
})

test_that("palma ratio is correctly calculated", {
  selected_ids <- c(
    "89a88cd909bffff",
    "89a88cdb57bffff",
    "89a88cdb597ffff",
    "89a88cdb5b3ffff",
    "89a88cdb5cfffff"
  )
  access_data <- cumulative_cutoff(
    travel_matrix[from_id %in% selected_ids],
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )

  result <- tester(access_data)
  result[, palma_ratio := round(palma_ratio, 4)]

  expected_result <- data.table::data.table(
    mode = c("transit", "transit2"),
    palma_ratio = rep(1.0911, 2)
  )
  expect_identical(result, expected_result)

  access_data <- access_data[!(id == "89a88cdb5cfffff" & mode == "transit2")]
  result <- tester(access_data)
  result[, palma_ratio := round(palma_ratio, 4)]

  expected_result <- data.table::data.table(
    mode = c("transit", "transit2"),
    palma_ratio = c(1.0911, 0.5249)
  )
  expect_identical(result, expected_result)
})

test_that("works even if access_data and sociodem_data has specific colnames", {
  selected_ids <- c(
    "89a88cdb57bffff",
    "89a88cdb5b3ffff"
  )
  access_data <- cumulative_cutoff(
    travel_matrix[from_id %in% selected_ids],
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )
  expected_result <- tester(access_data)

  access_data[, opportunity := "oi"]
  result <- suppressWarnings(tester(access_data))
  expect_identical(expected_result, result)

  access_data[, opportunity := NULL]
  land_use_data[, population_temp := population]
  land_use_data[, population := 1]
  result <- tester(access_data, population = "population_temp")
  expect_identical(expected_result, result)

  land_use_data[, population := population_temp]
  land_use_data[, population_temp := NULL]
  land_use_data[, income := "oi"]
  result <- tester(access_data)
  expect_identical(expected_result, result)

  land_use_data[, income := NULL]
  access_data[, group_by := "oi"]
  result <- suppressWarnings(tester(access_data))
  expect_identical(expected_result, result)

  access_data[, group_by := NULL]
})

test_that("handles missing data correctly", {
  # when access data is not null and it's missing either wealthiest or poorest
  # cells, palma should be NA, both with group_by = character(0) or something.
  # when access data is null, function should return a dataframe with 0 rows in
  # both cases

  selected_ids <- c(
    "89a88cdb57bffff",
    "89a88cdb5b3ffff"
  )
  custom_access <- cumulative_cutoff(
    travel_matrix[from_id %in% selected_ids],
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )

  result <- tester(
    custom_access[!(id == "89a88cdb5b3ffff" & mode == "transit2")]
  )
  result[, palma_ratio := round(palma_ratio, 4)]
  expect_identical(
    result,
    data.table::data.table(
      mode = c("transit", "transit2"),
      palma_ratio = c(0.5249, NA)
    )
  )

  result <- tester(
    custom_access[!(id == "89a88cdb57bffff" & mode == "transit2")]
  )
  result[, palma_ratio := round(palma_ratio, 4)]
  data.table::setkeyv(result, NULL)
  expect_identical(
    result,
    data.table::data.table(
      mode = c("transit", "transit2"),
      palma_ratio = c(0.5249, NA)
    )
  )

  custom_access <- custom_access[mode != "transit2"]

  # one row of custom_access is a wealthy cell and the other is a poor one

  result <- tester(custom_access[1])
  expect_identical(
    result,
    data.table::data.table(mode = "transit", palma_ratio = NA_real_)
  )

  result <- tester(custom_access[2])
  data.table::setkeyv(result, NULL)
  expect_identical(
    result,
    data.table::data.table(mode = "transit", palma_ratio = NA_real_)
  )

  suppressWarnings(result <- tester(custom_access[1], group_by = character()))
  expect_identical(result, data.table::data.table(palma_ratio = NA_real_))

  suppressWarnings(result <- tester(custom_access[2], group_by = character()))
  expect_identical(result, data.table::data.table(palma_ratio = NA_real_))

  no_access <- data.table::data.table(
    id = character(),
    mode = character(),
    jobs = integer()
  )

  result <- tester(no_access)
  expect_identical(
    result,
    data.table::data.table(mode = character(), palma_ratio = numeric())
  )

  suppressWarnings(result <- tester(no_access, group_by = character()))
  expect_identical(result, data.table::data.table(palma_ratio = numeric()))
})

test_that("result doesn't depend on the scale of the population weights", {
  access_data <- cumulative_cutoff(
    travel_matrix,
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )
  population_shares <- data.table::copy(land_use_data)
  population_shares[, population := population / sum(population)]

  expected <- tester(access_data)
  result <- tester(access_data, population_shares)
  expect_false(anyNA(result$palma_ratio))
  expect_equal(result, expected)
})

test_that("only returns the group_by combinations present in the data", {
  transit_matrix <- travel_matrix[mode == "transit"]
  transit_matrix[, mode := NULL]

  car_am <- cumulative_cutoff(
    transit_matrix,
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30
  )
  car_am[, `:=`(mode = "car", period = "am")]

  bus_pm <- data.table::copy(car_am)
  bus_pm[, `:=`(mode = "bus", period = "pm")]

  result <- tester(rbind(car_am, bus_pm), group_by = c("mode", "period"))
  expect_identical(nrow(result), 2L)
  expect_setequal(paste(result$mode, result$period), c("car am", "bus pm"))
  expect_null(data.table::key(result))
})

test_that("large integer populations don't overflow", {
  # with equal populations, the 40% and 90% income quantiles are 4.6 and 9.1,
  # so ids 1 to 4 are the poorest and id 10 is the wealthiest. the palma ratio
  # is 10 / mean(1:4) = 4

  accessibility_data <- data.table::data.table(
    id = as.character(1:10),
    jobs = as.numeric(1:10)
  )
  sociodemographic_data <- data.table::data.table(
    id = as.character(1:10),
    population = rep(1000000000L, 10),
    income_per_capita = as.numeric(1:10)
  )

  result <- tester(
    accessibility_data,
    sociodemographic_data,
    group_by = character(0)
  )
  expect_equal(result$palma_ratio, 4)
})
