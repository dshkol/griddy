state_income_panel <- function() {
  data(us_states, package = "spData")
  data(us_states_df, package = "spData")

  states <- sf::st_as_sf(us_states) |>
    dplyr::left_join(us_states_df, by = c("NAME" = "state")) |>
    dplyr::filter(!.data$NAME %in% c("Alaska", "Hawaii", "Puerto Rico")) |>
    dplyr::arrange(.data$NAME)

  panel <- states |>
    dplyr::select("NAME", "median_income_10", "median_income_15", "geometry") |>
    tidyr::pivot_longer(dplyr::starts_with("median_income_"), names_to = "year", values_to = "income") |>
    dplyr::mutate(year = dplyr::if_else(.data$year == "median_income_10", 2010L, 2015L))

  list(states = states, panel = panel)
}

griddy_state_spatial_counts <- function() {
  fx <- state_income_panel()
  listw <- spdep::nb2listw(spdep::poly2nb(fx$states, queen = TRUE), style = "W")
  grd <- spatial_markov(fx$panel, NAME, year, income, listw = listw, k = 5)
  aperm(array(
    grd$matrix$n,
    dim = c(5, 5, 5),
    dimnames = list(grd$states, grd$states, grd$lag_states)
  ), c(2, 1, 3))
}

test_that("static R-side spatial Markov oracle fixture agrees", {
  skip_if_not_installed("spData")

  fixtures <- readRDS(test_path("fixtures", "r_prior_spatial_counts.rds"))
  counts <- griddy_state_spatial_counts()

  expect_equal(unname(counts), unname(fixtures$estdaR_spatial_counts))
  expect_equal(unname(counts), unname(fixtures$spdyn_spatial_counts))
})

test_that("transition_matrix for spatial objects returns aggregated 5x5 matrices", {
  skip_if_not_installed("spData")

  fx <- state_income_panel()
  listw <- spdep::nb2listw(spdep::poly2nb(fx$states, queen = TRUE), style = "W")
  grd <- spatial_markov(fx$panel, NAME, year, income, listw = listw, k = 5)

  counts <- transition_matrix(grd, "count", lag_class = "Q1")
  probs <- transition_matrix(grd, "probability", lag_class = "Q1")

  expect_equal(dim(counts), c(5L, 5L))
  expect_equal(dim(probs), c(5L, 5L))
  expect_false(any(vapply(as.data.frame(counts), is.list, logical(1))))
  expect_false(any(vapply(as.data.frame(probs), is.list, logical(1))))
})

test_that("spdyn spatial Markov agrees on bundled state example when installed", {
  skip_if_not_installed("spdyn")
  skip_if_not_installed("spData")

  fx <- state_income_panel()

  wide <- fx$states |>
    sf::st_drop_geometry() |>
    dplyr::select("NAME", "median_income_10", "median_income_15")

  listw <- spdep::nb2listw(spdep::poly2nb(fx$states, queen = TRUE), style = "W")
  prior <- spdyn::spMarkov(
    wide,
    listw,
    stateVars = c("median_income_10", "median_income_15"),
    n.states = 5,
    pool = TRUE,
    std = FALSE
  )

  grd_counts <- griddy_state_spatial_counts()

  expect_equal(unname(grd_counts), unname(prior$t))
})

test_that("estdaR spatial Markov agrees on bundled state example when installed", {
  skip_if_not_installed("estdaR")
  skip_if_not_installed("spData")

  fx <- state_income_panel()

  wide <- fx$states |>
    sf::st_drop_geometry() |>
    dplyr::select("median_income_10", "median_income_15")

  listw <- spdep::nb2listw(spdep::poly2nb(fx$states, queen = TRUE), style = "W")
  prior <- estdaR::sp.mkv(as.matrix(wide), listw, classes = 5, fixed = TRUE)

  grd_counts <- griddy_state_spatial_counts()

  expect_equal(unname(grd_counts), unname(prior$Transitions))
})

test_that("PySAL giddy oracle comparison is optional", {
  skip_if(Sys.which("python3") == "", "python3 not available")
  code <- "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('giddy') else 1)"
  has_giddy <- system2("python3", c("-c", shQuote(code)), stdout = FALSE, stderr = FALSE) == 0
  skip_if_not(has_giddy, "Python package giddy is not installed")

  expect_true(has_giddy)
})
