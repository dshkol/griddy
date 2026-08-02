toy_prob <- function() {
  matrix(
    c(0.9, 0.1, 0.2, 0.8),
    nrow = 2, byrow = TRUE,
    dimnames = list(c("Q1", "Q2"), c("Q1", "Q2"))
  )
}

toy_markov <- function() {
  panel <- data.frame(
    id = rep(letters[1:4], each = 3),
    year = rep(2020:2022, times = 4),
    value = c(8, 9, 15, 10, 12, 13, 15, 9, 16, 20, 22, 25)
  )
  classes <- classify_dynamics(panel, id, year, value, k = 2)
  markov_dynamics(classes, id, year, class)
}

test_that("sojourn_time matches the closed form", {
  expect_equal(sojourn_time(toy_prob()), c(Q1 = 10, Q2 = 5))
})

test_that("sojourn_time is infinite for absorbing classes", {
  p <- matrix(c(0.5, 0.5, 0, 1), nrow = 2, byrow = TRUE)
  expect_equal(unname(sojourn_time(p)), c(2, Inf))
})

test_that("first_passage matches the two-state closed form", {
  m <- first_passage(toy_prob())
  expect_equal(unname(m), matrix(c(1.5, 10, 5, 3), nrow = 2, byrow = TRUE))
  expect_equal(rownames(m), c("Q1", "Q2"))
  expect_equal(unname(diag(m)), unname(1 / steady_state(toy_prob())))
})

test_that("first_passage rejects reducible chains", {
  absorbing <- matrix(c(0.5, 0.5, 0, 1), nrow = 2, byrow = TRUE)
  expect_error(first_passage(absorbing), "irreducible")
})

test_that("first_passage supports irreducible periodic chains", {
  periodic <- matrix(c(0, 1, 1, 0), nrow = 2, byrow = TRUE)

  expect_equal(
    unname(first_passage(periodic)),
    matrix(c(2, 1, 1, 2), nrow = 2, byrow = TRUE)
  )
})

test_that("mobility_index matches closed forms on the toy matrix", {
  out <- mobility_index(toy_prob())
  expect_named(
    out,
    c("prais", "determinant", "eigen", "bartholomew1", "bartholomew2")
  )
  expect_equal(unname(out["prais"]), 0.3)
  expect_equal(unname(out["determinant"]), 0.3)
  expect_equal(unname(out["eigen"]), 0.3)
  expect_equal(unname(out["bartholomew1"]), 0.3)
  expect_equal(unname(out["bartholomew2"]), 0.15)
})

test_that("mobility indices are zero for the identity matrix", {
  out <- mobility_index(diag(3))
  expect_equal(unname(out), rep(0, 5))
})

test_that("grd_markov methods agree with matrix methods", {
  markov <- toy_markov()
  p <- .grd_check_prob_matrix(markov$probabilities)

  expect_equal(unname(sojourn_time(markov)), unname(sojourn_time(p)))
  expect_equal(names(sojourn_time(markov)), markov$states)
  expect_equal(unname(first_passage(markov)), unname(first_passage(p)))
  expect_equal(rownames(first_passage(markov)), markov$states)
  expect_equal(mobility_index(markov), mobility_index(p))
})

test_that("invalid transition matrices are rejected", {
  expect_error(sojourn_time(matrix(1, 2, 3)), "square")
  expect_error(sojourn_time(matrix(c(0.4, 0.4, 0.5, 0.5), 2)), "sum to 1")
  expect_error(
    first_passage(matrix(c(0.9, NA, 0.2, 0.8), 2, byrow = TRUE)),
    "missing"
  )
  expect_error(mobility_index(toy_prob(), initial = c(0.4, 0.4)), "initial")
  expect_error(mobility_index(toy_prob(), initial = c(NA, 1)), "finite")
  expect_error(mobility_index(toy_prob(), initial = c(Inf, 0)), "finite")
  expect_error(mobility_index(toy_prob(), initial = c("0.5", "0.5")), "finite")
  expect_error(mobility_index(matrix(1, 1, 1)), "two classes")
})
