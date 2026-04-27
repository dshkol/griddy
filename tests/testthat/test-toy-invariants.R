test_that("all-upward panel produces a strictly upper-triangular count matrix", {
  dat <- tibble::tibble(
    id = rep(letters[1:3], each = 3),
    year = rep(1:3, times = 3),
    state = factor(
      c("low", "mid", "high", "low", "mid", "high", "low", "mid", "high"),
      levels = c("low", "mid", "high"),
      ordered = TRUE
    )
  )

  mk <- markov_dynamics(dat, id, year, state)

  counts <- unname(mk$counts)
  expect_equal(counts[lower.tri(counts, diag = TRUE)], rep(0, 6))
  expect_equal(counts[1, 2], 3)
  expect_equal(counts[2, 3], 3)
})

test_that("reducible chain with an absorbing state has an absorbing row", {
  dat <- tibble::tibble(
    id = rep(c("trap", "free"), each = 4),
    year = rep(1:4, times = 2),
    state = factor(
      c("a", "a", "a", "a", "a", "b", "b", "b"),
      levels = c("a", "b"),
      ordered = TRUE
    )
  )

  mk <- markov_dynamics(dat, id, year, state)

  expect_equal(unname(mk$probabilities)[2, ], c(0, 1))
})

test_that("row probabilities sum to 1 on non-empty rows and are NA on empty rows", {
  dat <- tibble::tibble(
    id = rep(c("a", "b"), each = 3),
    year = rep(1:3, times = 2),
    state = factor(
      c("low", "low", "high", "low", "high", "high"),
      levels = c("low", "high"),
      ordered = TRUE
    )
  )

  mk <- markov_dynamics(dat, id, year, state)
  probs <- mk$probabilities

  for (i in seq_len(nrow(probs))) {
    row_total <- sum(mk$counts[i, ])
    if (row_total > 0) {
      expect_equal(sum(probs[i, ]), 1, tolerance = 1e-12)
    } else {
      expect_true(all(is.na(probs[i, ])))
    }
  }
})

test_that("spatial Markov on a tiny known grid agrees with hand calculation", {
  panel <- tibble::tibble(
    id = rep(1:4, each = 2),
    year = rep(c(1, 2), times = 4),
    value = c(
      1, 1,
      1, 2,
      2, 2,
      2, 3
    )
  )

  listw <- spdep::nb2listw(spdep::cell2nb(2, 2, type = "queen"), style = "W")
  spatial <- spatial_markov(panel, id, year, value, listw = listw, k = 2)

  total_observed <- sum(spatial$matrix$n)
  expect_equal(total_observed, 4)

  for (lag in spatial$lag_states) {
    sub <- dplyr::filter(spatial$matrix, .data$lag_class == lag)
    by_from <- sub |>
      dplyr::group_by(.data$from_state) |>
      dplyr::summarise(prob_total = sum(.data$probability), n_total = sum(.data$n), .groups = "drop")
    for (i in seq_len(nrow(by_from))) {
      if (by_from$n_total[i] > 0) {
        expect_equal(by_from$prob_total[i], 1, tolerance = 1e-12)
      } else {
        expect_true(is.na(by_from$prob_total[i]) || by_from$prob_total[i] == 0)
      }
    }
  }
})

test_that("results are stable under row reordering when id and time are supplied", {
  dat <- tibble::tibble(
    id = rep(c("a", "b", "c"), each = 3),
    year = rep(2000:2002, times = 3),
    value = c(1, 2, 3, 4, 5, 6, 7, 8, 9)
  )
  shuffled <- dat[sample.int(nrow(dat)), ]

  mk1 <- markov_dynamics(classify_dynamics(dat, id, year, value, k = 3), id, year, class)
  mk2 <- markov_dynamics(classify_dynamics(shuffled, id, year, value, k = 3), id, year, class)

  expect_equal(unname(mk1$counts), unname(mk2$counts))
  expect_equal(unname(mk1$probabilities), unname(mk2$probabilities))
})

test_that("rank mobility endpoint changes sum to zero on a complete untied panel", {
  dat <- tibble::tibble(
    id = rep(letters[1:5], each = 2),
    year = rep(c(1, 2), times = 5),
    value = c(10, 14, 20, 21, 30, 32, 40, 41, 50, 13)
  )

  mob <- rank_mobility(dat, id, year, value)
  expect_equal(sum(mob$rank_change), 0)
})
