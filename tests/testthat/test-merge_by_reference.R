tester <- function(data,
                   land_use_data,
                   opportunity = "jobs",
                   left_df_idcol = "to_id") {
  merge_by_reference(data, land_use_data, opportunity, left_df_idcol)
}

test_that("matches character ids and gives NA to missing ids", {
  data <- data.table::data.table(
    from_id = c("a", "a", "b", "b"),
    to_id = c("a", "c", "b", "z")
  )
  land_use_data <- data.table::data.table(
    id = c("c", "b", "a"),
    jobs = c(30, 20, 10)
  )
  original_land_use <- data.table::copy(land_use_data)

  tester(data, land_use_data)
  expect_identical(data$jobs, c(10, 30, 20, NA))

  tester(data, land_use_data, "jobs", left_df_idcol = "from_id")
  expect_identical(data$jobs, c(10, 10, 20, 20))

  expect_identical(land_use_data, original_land_use)
})

test_that("matches numeric and factor ids", {
  data <- data.table::data.table(to_id = c(2L, 1L, 3L))
  land_use_data <- data.table::data.table(id = c(1, 2), jobs = c(5L, 7L))

  tester(data, land_use_data)
  expect_identical(data$jobs, c(7L, 5L, NA))

  data <- data.table::data.table(to_id = factor(c("b", "a")))
  land_use_data <- data.frame(id = c("a", "b"), jobs = c(1, 2))

  tester(data, land_use_data)
  expect_identical(data$jobs, c(2, 1))
})

test_that("na_as_zero turns NA values and missing ids into 0", {
  data <- data.table::data.table(to_id = c("a", "b", "c", "z"))
  land_use_data <- data.table::data.table(
    id = c("a", "b", "c"),
    jobs = c(10L, NA, 5L)
  )
  original_land_use <- data.table::copy(land_use_data)

  merge_by_reference(data, land_use_data, "jobs", "to_id", na_as_zero = TRUE)
  expect_identical(data$jobs, c(10L, 0L, 5L, 0L))

  merge_by_reference(data, land_use_data, "jobs", "to_id")
  expect_identical(data$jobs, c(10L, NA, 5L, NA))

  expect_identical(land_use_data, original_land_use)
})
