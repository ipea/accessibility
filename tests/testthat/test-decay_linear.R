tester <- function(cutoff = 20) decay_linear(cutoff)

test_that("adequately raises errors", {
  expect_error(tester("banana"))
  expect_error(tester(-1))
  expect_error(tester(Inf))
  expect_error(tester(NA))
  expect_error(tester(numeric(0)))
  expect_error(tester(c(1, 1)))
})

test_that("output is a decay function that returns a list of numeric vectors", {
  expect_is(tester(), "function")

  output_fn <- tester()
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 1)
  expect_named(output_list, "20")

  expect_equal(
    output_fn(c(0, 5, 10, 20, 60))[["20"]],
    c(1, 0.75, 0.5, 0, 0)
  )

  output_fn <- tester(30)
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 1)
  expect_named(output_list, "30")

  output <- output_fn(c(0, 10, 15, 30, 60))
  output <- lapply(output, function(x) round(x, 4))
  expect_equal(
    output[["30"]],
    c(1, 0.6667, 0.5, 0, 0)
  )

  output_fn <- tester(c(20, 30))
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 2)
  expect_named(output_list, c("20", "30"))

  expect_equal(
    output_fn(c(0, 5, 10, 20, 60))[["20"]],
    c(1, 0.75, 0.5, 0, 0)
  )
  expect_equal(
    round(output_fn(c(0, 10, 15, 30, 60))[["30"]], 4),
    c(1, 0.6667, 0.5, 0, 0)
  )
})

test_that("output fn returns empty numeric if receives empty numeric/integer", {
  output_fn <- tester(c(20, 30))

  expect_identical(output_fn(integer())[["20"]], numeric())
  expect_identical(output_fn(integer())[["30"]], numeric())

  expect_identical(output_fn(numeric())[["20"]], numeric())
  expect_identical(output_fn(numeric())[["30"]], numeric())
})

test_that("raises an error if cutoff is 0", {
  expect_error(tester(0), regexp = "Value must be greater than 0")
  expect_error(tester(c(0, 30)), regexp = "Value must be greater than 0")
})
