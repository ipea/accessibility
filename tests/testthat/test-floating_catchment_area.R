# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(
  travel_matrix = smaller_matrix,
  land_use_data = get("land_use_data", envir = parent.frame()),
  opportunity = "jobs",
  travel_cost = "travel_time",
  demand = "population",
  method = "2sfca",
  decay_function = decay_binary(45),
  group_by = "mode",
  fill_missing_ids = TRUE
) {
  floating_catchment_area(
    travel_matrix,
    land_use_data,
    opportunity,
    travel_cost,
    demand,
    method,
    decay_function,
    group_by,
    fill_missing_ids
  )
}


test_that("raises errors due to incorrect input", {
  expect_error(tester(method = 1))
  expect_error(tester(method = "a"))
  expect_error(tester(method = c("bfca", "bfca")))

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
      jobs = c(233L, 0L, 195L, 372L)
    )
  )

  result <- tester(small_travel_matrix, fill_missing_ids = FALSE)
  result[, jobs := as.integer(jobs)]
  expect_identical(
    result,
    data.table::data.table(
      id = c("89a88cdb57bffff", "89a88cdb597ffff", "89a88cdb597ffff"),
      mode = c("transit", "transit", "transit2"),
      jobs = c(233L, 195L, 372L)
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
  result[, jobs := round(jobs, digits = 4)]
  expect_identical(
    result,
    data.table::data.table(
      id = rep(selected_ids, 2),
      mode = rep(c("transit", "transit2"), each = 5),
      jobs = 0.1108
    )
  )
})

test_that("calculates 2sfca correctly", {
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

  result <- tester(smaller_travel_matrix, method = "2sfca")
  result[, jobs := round(jobs, digits = 4)]
  expect_identical(
    result,
    data.table::data.table(
      id = rep(selected_ids, 2),
      mode = rep(c("transit", "transit2"), each = 5),
      jobs = c(0.0152, 0.1491, 0.1491, 0.1068, 0)
    )
  )
})

test_that("calculates bfca correctly", {
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

  result <- tester(smaller_travel_matrix, method = "bfca")
  result[, jobs := round(jobs, digits = 4)]
  expect_identical(
    result,
    data.table::data.table(
      id = rep(selected_ids, 2),
      mode = rep(c("transit", "transit2"), each = 5),
      jobs = c(0.0094, 0.1993, 0.1993, 0.1147, 0)
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

test_that("results are grouped by decay_function_arg when needed", {
  small_travel_matrix <- travel_matrix[
    from_id %in% c("89a88cdb57bffff", "89a88cdb597ffff") &
      mode != "transit2"
  ]

  result <- tester(
    small_travel_matrix,
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
      jobs = c(456.32, 272.26, 456.85, 271.10)
    )
  )
})

test_that("2sfca and bfca match hand-computed values on a toy example", {
  # 3 zones, asymmetric costs (a->b = 10 but b->a = 20), linear decay with
  # cutoff 40, so f(c) = 1 - c / 40:
  #        to a   to b   to c
  # from a 1      0.75   0.50     row sums: a 2.25, b 1.75, c 1.75
  # from b 0.50   1      0.25     col sums: a 2.00, b 2.00, c 1.75
  # from c 0.50   0.25   1
  # opportunities S = (10, 20, 30); population P = (10, 5, 5)
  toy_matrix <- data.table::data.table(
    from_id = rep(c("a", "b", "c"), each = 3),
    to_id = rep(c("a", "b", "c"), 3),
    travel_time = c(0, 10, 20, 20, 0, 30, 20, 30, 0)
  )
  toy_land_use <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10, 20, 30),
    population = c(10, 5, 5)
  )

  toy_fca <- function(method) {
    floating_catchment_area(
      toy_matrix,
      toy_land_use,
      opportunity = "jobs",
      travel_cost = "travel_time",
      demand = "population",
      method = method,
      decay_function = decay_linear(cutoff = 40)
    )
  }

  # 2SFCA (Luo & Wang 2003): R_j = S_j / sum_k P_k f(c_kj);
  # A_i = sum_j R_j f(c_ij)
  # R_a = 10 / (10 * 1    + 5 * 0.5 + 5 * 0.5 ) = 10 / 15    = 2 / 3
  # R_b = 20 / (10 * 0.75 + 5 * 1   + 5 * 0.25) = 20 / 13.75 = 16 / 11
  # R_c = 30 / (10 * 0.5  + 5 * 0.25 + 5 * 1  ) = 30 / 11.25 = 8 / 3
  # A_a = 2/3 + 0.75 * 16/11 + 0.5 * 8/3 = 34 / 11
  # A_b = 0.5 * 2/3 + 16/11 + 0.25 * 8/3 = 27 / 11
  # A_c = 0.5 * 2/3 + 0.25 * 16/11 + 8/3 = 37 / 11
  result <- toy_fca("2sfca")
  expect_equal(
    result,
    data.table::data.table(
      id = c("a", "b", "c"),
      jobs = c(34 / 11, 27 / 11, 37 / 11)
    )
  )
  # 2SFCA preserves the total supply: sum_i P_i A_i = sum_j S_j = 60
  expect_equal(sum(toy_land_use$population * result$jobs), 60)

  # BFCA (Paez et al. 2019): f is balanced by origin, Wi_ij = f_ij / sum_j f_ij,
  # to allocate demand, and by destination, Wj_ij = f_ij / sum_i f_ij, to
  # allocate the level of service:
  # R_j = S_j / sum_k P_k Wi_kj; A_i = sum_j R_j Wj_ij
  # demand: D_a = 10 * 4/9 + 5 * 2/7 + 5 * 2/7 = 460 / 63
  #         D_b = 10 * 1/3 + 5 * 4/7 + 5 * 1/7 = 145 / 21
  #         D_c = 10 * 2/9 + 5 * 1/7 + 5 * 4/7 = 365 / 63
  # ratios: R_a = 10 / D_a = 63 / 46, R_b = 20 / D_b = 84 / 29,
  #         R_c = 30 / D_c = 378 / 73
  r_a <- 63 / 46
  r_b <- 84 / 29
  r_c <- 378 / 73
  result <- toy_fca("bfca")
  expect_equal(
    result,
    data.table::data.table(
      id = c("a", "b", "c"),
      jobs = c(
        r_a * 0.5 + r_b * 0.375 + r_c * 2 / 7,
        r_a * 0.25 + r_b * 0.5 + r_c * 1 / 7,
        r_a * 0.25 + r_b * 0.125 + r_c * 4 / 7
      )
    )
  )
  # BFCA does not inflate the level of service: sum_i A_i = sum_j R_j
  expect_equal(sum(result$jobs), r_a + r_b + r_c)
})
