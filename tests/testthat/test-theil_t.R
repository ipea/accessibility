# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

na_decile_ids <- land_use_data[is.na(land_use_data$income_decile), ]$id
sociodem_data <- land_use_data[! id %in% na_decile_ids]

tester <- function(accessibility_data = small_access,
                   sociodemographic_data = sociodem_data,
                   opportunity = "jobs",
                   population = "population",
                   socioeconomic_groups = "income_decile",
                   group_by = "mode") {
  theil_t(
    accessibility_data,
    sociodemographic_data,
    opportunity,
    population,
    socioeconomic_groups,
    group_by
  )
}

test_that("raises errors due to incorrect input", {
  expect_error(tester(opportunity = 1))
  expect_error(tester(opportunity = c("schools", "jobs")))

  expect_error(tester(population = 1))
  expect_error(tester(population = c("schools", "jobs")))

  expect_error(tester(socioeconomic_groups = 1))
  expect_error(tester(socioeconomic_groups = c("income_decile", "jobs")))

  expect_error(tester(group_by = 1))
  expect_error(tester(group_by = NA))
  expect_error(tester(group_by = "id"))
  expect_error(tester(group_by = c("mode", "mode")))

  expect_error(tester(as.list(small_access)))
  expect_error(tester(small_access[, .(oi = id, jobs, mode)]))
  expect_error(tester(small_access[, .(id, oi = jobs, mode)]))
  expect_error(tester(small_access[, .(id, jobs, oi = mode)]))

  expect_error(tester(sociodemographic_data = as.list(sociodem_data)))
  expect_error(
    tester(
      sociodemographic_data = sociodem_data[
        ,
        .(oi = id, population, income_decile)
      ]
    )
  )
  expect_error(
    tester(
      sociodemographic_data = sociodem_data[
        ,
        .(id, oi = population, income_decile)
      ]
    )
  )
  expect_error(
    tester(
      sociodemographic_data = sociodem_data[
        ,
        .(id, population, oi = income_decile)
      ]
    )
  )
})

test_that("throws warning if accessibility_data has an extra col", {
  expect_warning(tester(group_by = character(0)))
})

# tests when socioeconomic_groups is not NULL

test_that("returns dataframes with same class as accessibility_data's", {
  result <- tester()
  expect_is(result, "list")
  expect_is(result$summary, "data.table")
  expect_is(result$within_group_component, "data.table")
  expect_is(result$between_group_component, "data.table")

  result <- tester(sociodemographic_data = as.data.frame(sociodem_data))
  expect_is(result, "list")
  expect_is(result$summary, "data.table")
  expect_is(result$within_group_component, "data.table")
  expect_is(result$between_group_component, "data.table")

  result <- tester(as.data.frame(small_access))
  expect_is(result, "list")
  expect_false(inherits(result$summary, "data.table"))
  expect_is(result$summary, "data.frame")
  expect_false(inherits(result$within_group_component, "data.table"))
  expect_is(result$within_group_component, "data.frame")
  expect_false(inherits(result$between_group_component, "data.table"))
  expect_is(result$between_group_component, "data.frame")

  result <- tester(as.data.frame(small_access), as.data.frame(sociodem_data))
  expect_is(result, "list")
  expect_false(inherits(result$summary, "data.table"))
  expect_is(result$summary, "data.frame")
  expect_false(inherits(result$within_group_component, "data.table"))
  expect_is(result$within_group_component, "data.frame")
  expect_false(inherits(result$between_group_component, "data.table"))
  expect_is(result$between_group_component, "data.frame")
})

test_that("result has correct structure", {
  result <- tester()

  expect_true(ncol(result$summary) == 4)
  expect_is(result$summary$mode, "character")
  expect_is(result$summary$component, "character")
  expect_is(result$summary$value, "numeric")
  expect_is(result$summary$share_of_total, "numeric")

  expect_true(ncol(result$within_group_component) == 4)
  expect_is(result$within_group_component$mode, "character")
  expect_is(result$within_group_component$income_decile, "factor")
  expect_is(result$within_group_component$value, "numeric")
  expect_is(result$within_group_component$share_of_component, "numeric")

  expect_true(ncol(result$between_group_component) == 3)
  expect_is(result$between_group_component$mode, "character")
  expect_is(result$between_group_component$income_decile, "factor")
  expect_is(result$between_group_component$value, "numeric")

  suppressWarnings(result <- tester(group_by = character(0)))

  expect_true(ncol(result$summary) == 3)
  expect_is(result$summary$component, "character")
  expect_is(result$summary$value, "numeric")
  expect_is(result$summary$share_of_total, "numeric")

  expect_true(ncol(result$within_group_component) == 3)
  expect_is(result$within_group_component$income_decile, "factor")
  expect_is(result$within_group_component$value, "numeric")
  expect_is(result$within_group_component$share_of_component, "numeric")

  expect_true(ncol(result$between_group_component) == 2)
  expect_is(result$between_group_component$income_decile, "factor")
  expect_is(result$between_group_component$value, "numeric")

  result <- tester(small_access[0])

  expect_true(nrow(result$summary) == 0)
  expect_true(ncol(result$summary) == 4)
  expect_is(result$summary$mode, "character")
  expect_is(result$summary$component, "character")
  expect_is(result$summary$value, "numeric")
  expect_is(result$summary$share_of_total, "numeric")

  expect_true(nrow(result$within_group_component) == 0)
  expect_true(ncol(result$within_group_component) == 4)
  expect_is(result$within_group_component$mode, "character")
  expect_is(result$within_group_component$income_decile, "factor")
  expect_is(result$within_group_component$value, "numeric")
  expect_is(result$within_group_component$share_of_component, "numeric")

  expect_true(nrow(result$between_group_component) == 0)
  expect_true(ncol(result$between_group_component) == 3)
  expect_is(result$between_group_component$mode, "character")
  expect_is(result$between_group_component$income_decile, "factor")
  expect_is(result$between_group_component$value, "numeric")

  suppressWarnings(result <- tester(small_access[0], group_by = character(0)))

  expect_true(ncol(result$summary) == 3)
  expect_is(result$summary$component, "character")
  expect_is(result$summary$value, "numeric")
  expect_is(result$summary$share_of_total, "numeric")

  expect_true(nrow(result$within_group_component) == 0)
  expect_true(ncol(result$within_group_component) == 3)
  expect_is(result$within_group_component$income_decile, "factor")
  expect_is(result$within_group_component$value, "numeric")
  expect_is(result$within_group_component$share_of_component, "numeric")

  expect_true(nrow(result$between_group_component) == 0)
  expect_true(ncol(result$between_group_component) == 2)
  expect_is(result$between_group_component$income_decile, "factor")
  expect_is(result$between_group_component$value, "numeric")
})

test_that("input data sets remain unchanged", {
  # with the exception of some indexes

  original_access_data <- cumulative_cutoff(
    smaller_matrix,
    land_use_data,
    opportunity = "jobs",
    travel_cost = "travel_time",
    cutoff = 30,
    group_by = "mode"
  )
  original_sociodem_data <- land_use_data[! id %in% na_decile_ids]

  result <- tester()

  data.table::setindexv(small_access, NULL)
  expect_equal(original_access_data, small_access)
  data.table::setindex(sociodem_data, NULL)
  expect_equal(original_sociodem_data, sociodem_data)
})

test_that("theil t is correctly calculated", {
  selected_ids <- c(
    "89a88cd900bffff",
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

  result$summary[, value := round(value, 4)]
  result$summary[, share_of_total := round(share_of_total, 4)]
  expected_result <- data.table::data.table(
    mode = rep(c("transit", "transit2"), 3),
    component = rep(c("between_group", "within_group", "total"), each = 2),
    value = rep(c(0.0515, 0.0337, 0.0852), each = 2),
    share_of_total = rep(c(0.6044, 0.3956, 1), each = 2)
  )
  expect_identical(result$summary, expected_result)

  result$within_group_component[, value := round(value, 4)]
  expected_result <- data.table::data.table(
    mode = rep(c("transit", "transit2"), each = 4),
    income_decile = rep(factor(c(1, 3, 6, 10), levels = 1:10), 2),
    value = rep(c(0, 0, 0, 0.0337), 2),
    share_of_component = rep(c(0, 0, 0, 1), 2)
  )
  expect_identical(result$within_group_component, expected_result)

  result$between_group_component[, value := round(value, 4)]
  expected_result <- data.table::data.table(
    mode = rep(c("transit", "transit2"), each = 4),
    income_decile = rep(factor(c(1, 3, 6, 10), levels = 1:10), 2),
    value = rep(c(0.0243, -0.0579, -0.0042, 0.0894), 2)
  )
  expect_identical(result$between_group_component, expected_result)

  access_data <- access_data[!(id == "89a88cd900bffff" & mode == "transit2")]
  result <- tester(access_data)

  result$summary[, value := round(value, 4)]
  result$summary[, share_of_total := round(share_of_total, 4)]
  expected_result <- data.table::data.table(
    mode = rep(c("transit", "transit2"), 3),
    component = rep(c("between_group", "within_group", "total"), each = 2),
    value = c(0.0515, 0.0021, 0.0337, 0.0357, 0.0852, 0.0378),
    share_of_total = c(0.6044, 0.0545, 0.3956, 0.9455, 1, 1)
  )
  expect_identical(result$summary, expected_result)

  result$within_group_component[, value := round(value, 4)]
  expected_result <- data.table::data.table(
    mode = c(rep("transit", 4), rep("transit2", 3)),
    income_decile = factor(c(1, 3, 6, 10, 1, 6, 10), levels = 1:10),
    value = c(0, 0, 0, 0.0337, 0, 0, 0.0357),
    share_of_component = c(0, 0, 0, 1, 0, 0, 1)
  )
  expect_identical(result$within_group_component, expected_result)

  result$between_group_component[, value := round(value, 4)]
  expected_result <- data.table::data.table(
    mode = c(rep("transit", 4), rep("transit2", 3)),
    income_decile = factor(c(1, 3, 6, 10, 1, 6, 10), levels = 1:10),
    value = c(0.0243, -0.0579, -0.0042, 0.0894, -0.0142, -0.0113, 0.0276)
  )
  expect_identical(result$between_group_component, expected_result)
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
  sociodem_data[, population_temp := population]
  sociodem_data[, population := 1]
  result <- tester(access_data, population = "population_temp")
  expect_identical(expected_result, result)

  sociodem_data[, population := population_temp]
  sociodem_data[, population_temp := NULL]
  sociodem_data[, socioeconomic_groups := "oi"]
  result <- tester(access_data)
  expect_identical(expected_result, result)

  sociodem_data[, socioeconomic_groups := NULL]
  access_data[, group_by := "oi"]
  result <- suppressWarnings(tester(access_data))
  expect_identical(expected_result, result)

  access_data[, group_by := NULL]
})

# tests when socioeconomic_groups is NULL

null_tester <- function(...) tester(..., socioeconomic_groups = NULL)

test_that("returns dataframes with same class as accessibility_data's", {
  result <- null_tester()
  expect_is(result, "data.table")

  result <- null_tester(sociodemographic_data = as.data.frame(sociodem_data))
  expect_is(result, "data.table")

  result <- null_tester(as.data.frame(small_access))
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")

  result <- null_tester(
    as.data.frame(small_access),
    as.data.frame(sociodem_data)
  )
  expect_false(inherits(result, "data.table"))
  expect_is(result, "data.frame")
})

test_that("result has correct structure", {
  result <- null_tester()
  expect_true(ncol(result) == 2)
  expect_is(result$mode, "character")
  expect_is(result$theil_t, "numeric")

  suppressWarnings(result <- null_tester(group_by = character(0)))
  expect_true(ncol(result) == 1)
  expect_is(result$theil_t, "numeric")

  result <- null_tester(small_access[0])
  expect_true(nrow(result) == 0)
  expect_true(ncol(result) == 2)
  expect_is(result$mode, "character")
  expect_is(result$theil_t, "numeric")

  suppressWarnings(
    result <- null_tester(small_access[0], group_by = character(0))
  )
  expect_true(nrow(result) == 0)
  expect_true(ncol(result) == 1)
  expect_is(result$theil_t, "numeric")
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
  original_sociodem_data <- land_use_data[! id %in% na_decile_ids]

  result <- null_tester()

  expect_equal(original_access_data, small_access)
  data.table::setindex(sociodem_data, NULL)
  expect_equal(original_sociodem_data, sociodem_data)
})

test_that("theil t is correctly calculated", {
  selected_ids <- c(
    "89a88cd900bffff",
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

  result <- null_tester(access_data)
  result[, theil_t := round(theil_t, 4)]

  expected_result <- data.table::data.table(
    mode = c("transit", "transit2"),
    theil_t = 0.0852
  )
  expect_identical(result, expected_result)

  access_data <- access_data[!(id == "89a88cdb5cfffff" & mode == "transit2")]
  result <- null_tester(access_data)
  result[, theil_t := round(theil_t, 4)]

  expected_result <- data.table::data.table(
    mode = c("transit", "transit2"),
    theil_t = c(0.0852, 0.0839)
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
  expected_result <- null_tester(access_data)

  access_data[, opportunity := "oi"]
  result <- suppressWarnings(null_tester(access_data))
  expect_identical(expected_result, result)

  access_data[, opportunity := NULL]
  sociodem_data[, population_temp := population]
  sociodem_data[, population := 1]
  result <- null_tester(access_data, population = "population_temp")
  expect_identical(expected_result, result)

  sociodem_data[, population := population_temp]
  sociodem_data[, population_temp := NULL]
  access_data[, group_by := "oi"]
  result <- suppressWarnings(null_tester(access_data))
  expect_identical(expected_result, result)

  access_data[, group_by := NULL]
})

test_that("doesn't overflow with large integer opportunities and population", {
  # jobs * population exceeds .Machine$integer.max (~2.1e9)

  toy_access <- data.table::data.table(id = c("a", "b"), jobs = c(50000L, 100000L))
  toy_sociodem <- data.table::data.table(
    id = c("a", "b"),
    population = c(50000L, 30000L),
    income_per_capita = c(1, 2),
    income_decile = c(1, 2)
  )

  # population-weighted mean access: (5e4 * 5e4 + 3e4 * 1e5) / 8e4 = 68750

  ratio <- c(50000, 100000) / 68750
  expected_theil <- sum(c(0.625, 0.375) * ratio * log(ratio))

  result <- expect_silent(
    tester(
      toy_access,
      toy_sociodem,
      socioeconomic_groups = NULL,
      group_by = character(0)
    )
  )
  expect_equal(result$theil_t, expected_theil)

  result <- expect_silent(
    tester(toy_access, toy_sociodem, group_by = character(0))
  )
  expect_equal(result$summary[component == "total"]$value, expected_theil)
})

test_that("handles zero access with the 0 * log(0) = 0 convention", {
  toy_access <- data.table::data.table(
    id = rep(c("a", "b", "c", "d"), 2),
    mode = rep(c("car", "walk"), each = 4),
    jobs = c(0, 10, 20, 30, 0, 0, 0, 0)
  )
  toy_sociodem <- data.table::data.table(
    id = c("a", "b", "c", "d"),
    population = c(1, 1, 1, 1),
    income_decile = c(1, 1, 2, 2)
  )

  # car: mean access 15, so ratios are 0, 2/3, 4/3 and 2. walk: no one has
  # access, so the index is undefined

  ratio <- c(0, 10, 20, 30) / 15
  expected_theil <- mean(c(0, ratio[-1] * log(ratio[-1])))

  result <- tester(toy_access, toy_sociodem, socioeconomic_groups = NULL)
  expect_equal(result[mode == "car"]$theil_t, expected_theil)
  expect_true(is.na(result[mode == "walk"]$theil_t))

  # decomposition: deciles hold 1/6 and 5/6 of the access and half of the
  # population each

  access_share <- c(10, 50) / 60
  expected_between <- sum(access_share * log(access_share / 0.5))

  result <- tester(toy_access, toy_sociodem)
  car_summary <- result$summary[mode == "car"]
  expect_equal(
    car_summary[component == "between_group"]$value,
    expected_between
  )
  expect_equal(car_summary[component == "total"]$value, expected_theil)
  expect_false(anyNA(result$within_group_component[mode == "car"]$value))
  expect_true(all(is.na(result$summary[mode == "walk"]$value)))

  # a decile with no access has weight 0 in the within-group component

  toy_access <- data.table::data.table(
    id = c("a", "b", "c", "d"),
    jobs = c(0, 0, 20, 30)
  )
  ratio <- c(0, 0, 20, 30) / 12.5
  expected_theil <- mean(c(0, 0, ratio[3:4] * log(ratio[3:4])))

  result <- tester(toy_access, toy_sociodem, group_by = character(0))
  expect_equal(
    result$summary[component == "total"]$value,
    expected_theil
  )
  expect_equal(
    result$within_group_component[income_decile == 1]$value,
    0
  )
})
