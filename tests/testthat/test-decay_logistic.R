tester <- function(cutoff = c(20, 30), sd = c(2, 10)) {
  decay_logistic(cutoff, sd)
}

test_that("adequately raises errors", {
  expect_error(tester("a"))
  expect_error(tester(0))
  expect_error(tester(c(25, Inf)))
  expect_error(tester(c(25, NA)))
  expect_error(tester(integer()))

  expect_error(tester(cutoff = "a"))
  expect_error(tester(cutoff = 0))
  expect_error(tester(cutoff = 120))
  expect_error(tester(cutoff = c(25, Inf)))
  expect_error(tester(cutoff = c(25, NA)))
  expect_error(tester(cutoff = integer()))
})

test_that("output is a decay function that returns a list of numeric vctrs", {
  expect_is(tester(), "function")

  output_fn <- tester(c(20, 30), c(2, 10))
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 2L)
  expect_named(output_list, c("c20;sd2", "c30;sd10"))

  expect_equal(
    output_fn(c(0, 20))[["c20;sd2"]],
    c(1, 0.5)
  )

  expect_equal(
    output_fn(c(0, 30))[["c30;sd10"]],
    c(1, 0.502),
    tolerance = 0.001
  )

  output_fn <- tester(20, 2)
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 1L)
  expect_named(output_list, "c20;sd2")

  expect_equal(
    output_fn(c(0, 20))[["c20;sd2"]],
    c(1, 0.5)
  )
})

test_that("output fn returns empty numeric if receives empty numeric/integer", {
  output_fn <- tester(20, 2)

  expect_identical(output_fn(integer())[["c20;sd2"]], numeric())
  expect_identical(output_fn(numeric())[["c20;sd2"]], numeric())
})

test_that("raises an error if (cutoff, sd) pairs are duplicated", {
  expect_error(
    tester(c(30, 30), c(5, 5)),
    regexp = "duplicated[[:space:]]+.cutoff,[[:space:]]+sd.[[:space:]]+pairs"
  )
  expect_error(tester(c(30, 30), c(5, 10)), NA)
})
