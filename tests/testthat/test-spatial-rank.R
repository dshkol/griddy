make_grid_panel <- function() {
  geom <- sf::st_as_sf(
    tibble::tibble(
      id = c("a", "b", "c", "d"),
      x = c(0, 1, 0, 1),
      y = c(0, 0, 1, 1)
    ),
    coords = c("x", "y")
  ) |>
    sf::st_buffer(0.45)

  panel <- geom[rep(seq_len(nrow(geom)), each = 2), ] |>
    dplyr::mutate(
      year = rep(c(1, 2), times = 4),
      value = c(1, 3, 2, 4, 3, 2, 4, 1)
    ) |>
    dplyr::arrange(id, year)

  list(geom = geom, panel = panel)
}

test_that("spatial_markov conditional counts aggregate to classic counts", {
  fx <- make_grid_panel()
  nb <- spdep::cell2nb(2, 2, type = "queen")

  classes <- classify_dynamics(fx$panel, id, year, value, k = 2)
  mk <- markov_dynamics(classes, id, year, class)
  sm <- spatial_markov(fx$panel, id, year, value, nb = nb, k = 2)

  conditional_counts <- sm$matrix |>
    dplyr::group_by(from_state, to_state) |>
    dplyr::summarise(n = sum(n), .groups = "drop") |>
    dplyr::arrange(from_state, to_state)

  classic_counts <- as.data.frame(mk$counts) |>
    tibble::as_tibble() |>
    dplyr::transmute(from_state = Var1, to_state = Var2, n = Freq) |>
    dplyr::arrange(from_state, to_state)

  expect_equal(conditional_counts$n, classic_counts$n)
  expect_equal(nrow(lag_intervals(sm)), 2)
  expect_true(all(c("lag_lower", "lag_upper", "transition") %in% names(sm$matrix)))
  expect_true("transition" %in% names(sm$transitions))
})

test_that("rank_mobility endpoint changes sum to zero for complete untied ranks", {
  fx <- make_grid_panel()

  rm <- rank_mobility(fx$panel, id, year, value)

  expect_s3_class(rm, "grd_rank_mobility")
  expect_equal(sum(sf::st_drop_geometry(rm)$rank_change), 0)
  expect_true("geometry" %in% names(rm))
})

test_that("plot helpers return ggplot objects", {
  fx <- make_grid_panel()
  nb <- spdep::cell2nb(2, 2, type = "queen")
  classes <- classify_dynamics(fx$panel, id, year, value, k = 2)
  mk <- markov_dynamics(classes, id, year, class)
  sm <- spatial_markov(fx$panel, id, year, value, nb = nb, k = 2)
  rm <- rank_mobility(fx$panel, id, year, value)

  expect_s3_class(plot_transition_matrix(mk), "ggplot")
  expect_s3_class(plot_spatial_markov(sm), "ggplot")
  expect_s3_class(plot_rank_mobility(rm), "ggplot")
})
