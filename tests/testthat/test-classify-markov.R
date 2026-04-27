test_that("classify_dynamics creates ordered classes from long data", {
  dat <- tibble::tibble(
    id = rep(letters[1:4], each = 2),
    year = rep(c(2000, 2001), times = 4),
    value = c(1, 2, 2, 3, 3, 4, 4, 5)
  )

  out <- classify_dynamics(dat, id, year, value, k = 2)

  expect_s3_class(out, "grd_classes")
  expect_true(is.ordered(out$class))
  expect_equal(levels(out$class), c("Q1", "Q2"))
  expect_equal(nrow(class_intervals(out)), 2)
  expect_equal(class_intervals(out)$type, c("value", "value"))
})

test_that("markov_dynamics counts obvious transitions", {
  dat <- tibble::tibble(
    id = rep(c("a", "b", "c"), each = 2),
    year = rep(c(1, 2), times = 3),
    state = factor(c("low", "high", "low", "low", "high", "high"), levels = c("low", "high"), ordered = TRUE)
  )

  mk <- markov_dynamics(dat, id, year, state)

  expect_s3_class(mk, "grd_markov")
  expect_equal(unname(mk$counts), matrix(c(1, 1, 0, 1), nrow = 2, byrow = TRUE))
  expect_equal(unname(mk$probabilities), matrix(c(0.5, 0.5, 0, 1), nrow = 2, byrow = TRUE))
  expect_equal(sum(mk$counts), 3)
  expect_equal(mk$transitions$transition, c("low -> high", "low -> low", "high -> high"))
  expect_true("transition" %in% names(as.data.frame(mk)))
})

test_that("empty transition rows are explicit", {
  dat <- tibble::tibble(
    id = rep(c("a", "b"), each = 2),
    year = rep(c(1, 2), times = 2),
    state = factor(c("low", "low", "low", "low"), levels = c("low", "high"), ordered = TRUE)
  )

  mk <- markov_dynamics(dat, id, year, state)

  expect_equal(unname(mk$counts), matrix(c(2, 0, 0, 0), nrow = 2))
  expect_true(all(is.na(mk$probabilities[2, ])))
})

test_that("steady_state computes a simple stationary distribution", {
  P <- matrix(c(0.5, 0.5, 0.25, 0.75), nrow = 2, byrow = TRUE)
  ss <- steady_state(P)
  expect_equal(unname(ss), c(1 / 3, 2 / 3), tolerance = 1e-8)
})
