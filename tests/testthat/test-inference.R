nine_cell_spatial <- function() {
  panel <- data.frame(
    id = rep(1:9, each = 3),
    year = rep(2020:2022, times = 9),
    value = c(
      1, 2, 3, 4, 3, 5, 6, 7, 6, 8, 9, 10, 11, 10,
      12, 13, 14, 13, 15, 16, 17, 18, 17, 19, 20, 21, 20
    )
  )
  grid <- sf::st_sf(
    id = 1:9,
    geometry = sf::st_make_grid(
      sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 3, ymax = 3)),
      n = c(3, 3)
    )
  ) |>
    dplyr::mutate(
      nb = sfdep::st_contiguity(geometry),
      wt = sfdep::st_weights(nb)
    )
  spatial_markov(panel, id, year, value, geometry = grid, k = 3)
}

test_that("kullback statistic reproduces the published Kullback (1962) example", {
  s1 <- matrix(
    c(
      22, 11, 24, 2, 2, 7,
      5, 23, 15, 3, 42, 6,
      4, 21, 190, 25, 20, 34,
      0, 2, 14, 56, 14, 28,
      32, 15, 20, 10, 56, 14,
      5, 22, 31, 18, 13, 134
    ),
    nrow = 6, byrow = TRUE
  )
  s2 <- matrix(
    c(
      3, 6, 9, 3, 0, 8,
      1, 9, 3, 12, 27, 5,
      2, 9, 208, 32, 5, 18,
      0, 14, 32, 108, 40, 40,
      22, 14, 9, 26, 224, 14,
      1, 5, 13, 53, 13, 116
    ),
    nrow = 6, byrow = TRUE
  )

  out <- homogeneity_test(list(s1, s2))
  kb <- out[out$test == "kullback", ]

  expect_equal(kb$statistic, 160.961, tolerance = 1e-5)
  # The published table uses the unadjusted r(s - 1)(r - 1) = 30. Origin
  # state 4 never reaches destination 1 in either stratum, so the
  # Bickenbach-Bode count drops one degree of freedom.
  expect_equal(kb$df, 29L)
  expect_lt(kb$p_value, 1e-6)
})

test_that("kullback coincides with the likelihood-ratio test", {
  set.seed(260)
  for (shape in list(c(3, 2), c(4, 3), c(5, 4))) {
    r <- shape[1]
    s <- shape[2]
    mats <- replicate(s, matrix(rpois(r * r, 8), r), simplify = FALSE)
    out <- homogeneity_test(mats)
    lr <- out[out$test == "likelihood_ratio", ]
    kb <- out[out$test == "kullback", ]

    expect_equal(kb$statistic, lr$statistic, tolerance = 1e-10)
    expect_identical(kb$df, lr$df)
    expect_equal(kb$p_value, lr$p_value, tolerance = 1e-10)
  }
})

test_that("degrees of freedom exclude unobserved regimes and destinations", {
  # Origin 1 reaches destinations 1 and 2 in both regimes: (2 - 1) * (2 - 1).
  # Origin 2 has transitions in regime 1 only: (1 - 1) * (1 - 1).
  # Origin 3 reaches destinations 2 and 3 in both regimes: (2 - 1) * (2 - 1).
  m1 <- matrix(c(5, 2, 0, 3, 0, 0, 0, 1, 4), nrow = 3, byrow = TRUE)
  m2 <- matrix(c(2, 6, 0, 0, 0, 0, 0, 3, 2), nrow = 3, byrow = TRUE)

  out <- homogeneity_test(list(m1, m2))

  expect_equal(out$df, rep(2L, 3))
  expect_equal(
    out$statistic[out$test == "kullback"],
    out$statistic[out$test == "likelihood_ratio"],
    tolerance = 1e-10
  )

  # An origin state with no transitions in any regime adds nothing.
  m1[2, ] <- 0
  out_empty <- homogeneity_test(list(m1, m2))

  expect_equal(out_empty$df, rep(2L, 3))
  expect_equal(out_empty$statistic, out$statistic, tolerance = 1e-10)
})

test_that("identical regimes are homogeneous under every test", {
  m <- matrix(c(10, 5, 3, 12), nrow = 2)

  for (scale in c(1, 10, 100, 1000)) {
    out <- homogeneity_test(list(m * scale, m * scale))

    expect_equal(out$statistic, rep(0, 3), tolerance = 1e-9)
    expect_equal(out$p_value, rep(1, 3))
  }
})

test_that("homogeneity_test returns a tidy three-row tibble", {
  spatial <- nine_cell_spatial()
  out <- homogeneity_test(spatial)

  expect_s3_class(out, "tbl_df")
  expect_equal(out$test, c("chi2", "likelihood_ratio", "kullback"))
  expect_equal(names(out), c("test", "statistic", "df", "p_value"))
  expect_true(all(out$statistic >= 0))
  expect_true(all(out$df >= 0))
  expect_true(all(out$p_value >= 0 & out$p_value <= 1))
})

test_that("invalid inputs are rejected", {
  m <- matrix(c(10, 5, 3, 12), nrow = 2)

  expect_error(homogeneity_test(list(m)), "at least two regimes")
  expect_error(
    homogeneity_test(list(m, matrix(0, 3, 3))),
    "same dimensions"
  )
  expect_error(
    homogeneity_test(list(m, matrix(c(-1, 2, 3, 4), 2))),
    "non-negative"
  )
  expect_error(
    homogeneity_test(list(m, matrix(c(1, 2, 3, Inf), 2))),
    "finite"
  )
  expect_error(
    homogeneity_test(list(m, matrix(c(1, 2, 3, NA), 2))),
    "finite"
  )
  expect_error(
    homogeneity_test(list(m, matrix(c(1, 2, 3, 4.5), 2))),
    "whole-number"
  )
  expect_error(
    homogeneity_test(list(m, matrix(0, 2, 2))),
    "at least one transition"
  )
  expect_error(
    homogeneity_test(list(m, matrix(letters[1:4], 2))),
    "numeric"
  )
})
