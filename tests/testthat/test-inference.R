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
  expect_equal(kb$df, 30L)
  expect_lt(kb$p_value, 1e-6)
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
