weigh <- function(cost) list(a = exp(-0.1 * cost), b = cost ^ 2)

test_that("weights repeated costs as if each cost was weighted separately", {
  travel_cost <- c(10, NA, 0, 10, 20, NA, 0, 20, 10, Inf)
  expect_identical(weigh_unique_costs(travel_cost, weigh), weigh(travel_cost))

  names(travel_cost) <- letters[seq_along(travel_cost)]
  expect_identical(weigh_unique_costs(travel_cost, weigh), weigh(travel_cost))
})

test_that("weights mostly unique costs directly", {
  travel_cost <- c(1.5, 2.5, 3.5, 1.5)
  expect_identical(weigh_unique_costs(travel_cost, weigh), weigh(travel_cost))
  expect_identical(weigh_unique_costs(numeric(0), weigh), weigh(numeric(0)))
})
