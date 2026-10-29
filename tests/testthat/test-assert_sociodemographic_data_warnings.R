# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

tester <- function(sociodemographic_data = land_use_data,
                   accessibility_data = small_access,
                   population = NULL,
                   income = NULL,
                   extra_cols = NULL) {
  assert_sociodemographic_data(
    sociodemographic_data,
    accessibility_data,
    population,
    income,
    extra_cols
  )
}

test_that("warns if access_data contains ids not in sociodemographic_data", {
  expect_warning(
    tester(
      accessibility_data = rbind(
        small_access,
        data.table::data.table(id = "hehe", mode = "transit", jobs = 100)
      )
    )
  )
})

test_that("warns if cols contain NAs", {
  expect_warning(
    tester(
      rbind(
        land_use_data,
        data.table::data.table(id = "hehe"),
        fill = TRUE
      ),
      population = "population"
    )
  )

  expect_warning(
    tester(
      rbind(
        land_use_data,
        data.table::data.table(id = "hehe"),
        fill = TRUE
      ),
      extra_cols = "income_decile"
    )
  )

  expect_warning(
    tester(
      rbind(
        land_use_data,
        data.table::data.table(id = "hehe", population = 1),
        fill = TRUE
      ),
      income = "income_per_capita",
      population = "population"
    )
  )

  expect_warning(
    tester(
      rbind(
        land_use_data,
        data.table::data.table(id = "hehe", population = NA),
        fill = TRUE
      ),
      income = "income_per_capita",
      population = "population"
    )
  )

  # should not warn because all NA income entries have respective population
  # entries equal to 0
  expect_silent(
    tester(
      land_use_data,
      income = "income_per_capita",
      population = "population"
    )
  )
})

test_that("errors if sociodemographic_data has duplicated ids", {
  duplicated_sociodem <- rbind(land_use_data, land_use_data[1])
  expect_error(
    tester(duplicated_sociodem, population = "population"),
    regexp = "duplicated[[:space:]]+ids"
  )
})
