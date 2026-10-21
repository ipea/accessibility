tester <- function(steps = c(25, 50), weights = c(0.5, 0)) {
  decay_stepped(steps, weights)
}

test_that("adequately raises errors", {
  expect_error(tester("a"))
  expect_error(tester(0))
  expect_error(tester(c(25, Inf)))
  expect_error(tester(c(25, NA)))
  expect_error(tester(integer()))
  expect_error(tester(c(25, 25)))
  expect_error(tester(c(25, 20)))

  expect_error(tester(list(c(25, 50), "a")))
  expect_error(tester(list(c(25, 50), 0)))
  expect_error(tester(list(c(25, 50), c(25, Inf))))
  expect_error(tester(list(c(25, 50), c(25, NA))))
  expect_error(tester(list(c(25, 50), integer())))
  expect_error(tester(list(c(25, 50), c(25, 25))))
  expect_error(tester(list(c(25, 50), c(25, 20))))

  expect_error(tester(weights = "a"))
  expect_error(tester(weights = c(0.7, -1)))
  expect_error(tester(weights = c(1.5, 0)))
  expect_error(tester(weights = c(0.7, NA)))
  expect_error(tester(weights = 1))

  expect_error(tester(list(c(20, 50), c(30, 60)), weights = "a"))
  expect_error(tester(list(c(20, 50), c(30, 60)), weights = list("a", "b")))
  expect_error(tester(list(c(20, 50), c(30, 60)), weights = list(1)))
  expect_error(
    tester(list(c(20, 50), c(30, 60)), weights = list(c(0.5, 0), c(0.7, -1)))
  )
  expect_error(
    tester(list(c(20, 50), c(30, 60)), weights = list(c(0.5, 0), c(1.5, 0)))
  )
  expect_error(
    tester(list(c(20, 50), c(30, 60)), weights = list(c(0.5, 0), c(0.7, NA)))
  )
  expect_error(
    tester(list(c(20, 50), c(30, 60)), weights = list(c(0.5, 0), c(1)))
  )
})

test_that("output is a function that returns a list of numeric vectors", {
  expect_is(tester(), "function")

  output_fn <- tester()
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 1)
  expect_named(output_list, "s(25,50);w(0.5,0)")

  expect_equal(output_fn(c(5, 30, 55))[[1]], c(1, 0.5, 0))

  output_fn <- tester(weights = c(0.6, 0))
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 1)
  expect_named(output_list, "s(25,50);w(0.6,0)")

  expect_equal(output_fn(c(5, 30, 55))[[1]], c(1, 0.6, 0))

  output_fn <- tester(
    steps = list(c(25, 50), c(25, 50)),
    weights = list(c(0.5, 0), c(0.6, 0))
  )
  output_list <- output_fn(0)
  expect_is(output_list, "list")
  expect_length(output_list, 2)
  expect_named(output_list, c("s(25,50);w(0.5,0)", "s(25,50);w(0.6,0)"))

  expect_equal(output_fn(c(5, 30, 55))[[1]], c(1, 0.5, 0))
  expect_equal(output_fn(c(5, 30, 55))[[2]], c(1, 0.6, 0))
})

test_that("steps intervals are open on the right", {
  output_fn <- tester(c(10, 20, 30, 40), c(0.75, 0.5, 0.25, 0))

  expect_identical(
    output_fn(c(0, 10, 20, 30, 40))[[1]],
    c(1, 0.75, 0.5, 0.25, 0)
  )
})

test_that("output fn returns empty numeric if receives empty numeric/integer", {
  output_fn <- tester()

  expect_identical(output_fn(integer())[[1]], numeric())
  expect_identical(output_fn(numeric())[[1]], numeric())
})

test_that("raises an error if (steps, weights) pairs are duplicated", {
  expect_error(
    tester(list(c(10, 20), c(10, 20)), list(c(0.5, 0), c(0.5, 0))),
    regexp = "duplicated[[:space:]]+.steps,[[:space:]]+weights.[[:space:]]+pairs"
  )
  expect_error(
    tester(list(c(10L, 20L), c(10, 20)), list(c(0.5, 0), c(0.5, 0))),
    regexp = "duplicated[[:space:]]+.steps,[[:space:]]+weights.[[:space:]]+pairs"
  )
  expect_error(
    tester(list(c(10, 20), c(10, 20)), list(c(0.5, 0), c(0.6, 0))),
    NA
  )
})

test_that("returns NA without warnings when travel cost is NA", {
  output_fn <- tester(c(10, 20), c(0.5, 0))

  expect_silent(result <- output_fn(c(NA, 5, 15, 25)))
  expect_identical(result[[1]], c(NA, 1, 0.5, 0))
})
