# A 3 x 3 queen-contiguity grid with ids scattered across the cells, so the
# rows of `grid` are not in ascending order of `id`. The layout is not a
# symmetry of the grid, so matching by position gives the wrong neighbors.
nine_cell_fixture <- function() {
  cells <- sf::st_make_grid(
    sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 3, ymax = 3)),
    n = c(3, 3)
  )
  ids <- c("b", "g", "e", "i", "a", "h", "c", "f", "d")
  grid <- sf::st_sf(id = ids, geometry = cells)
  panel <- data.frame(
    id = rep(ids, each = 3),
    year = rep(2020:2022, times = 9),
    value = c(
      1, 2, 3, 4, 3, 5, 6, 7, 6, 8, 9, 10, 11, 10,
      12, 13, 14, 13, 15, 16, 17, 18, 17, 19, 20, 21, 20
    )
  )
  list(grid = grid, panel = panel)
}

with_weights <- function(geography) {
  dplyr::mutate(
    geography,
    nb = sfdep::st_contiguity(geometry),
    wt = sfdep::st_weights(nb)
  )
}

scramble <- function(n) {
  c(seq(2L, n, by = 2L), seq(1L, n, by = 2L))
}

expect_same_dynamics <- function(x, y) {
  expect_equal(x$lag_panel, y$lag_panel)
  expect_equal(x$transitions, y$transitions)
  expect_equal(x$matrix, y$matrix)
  expect_equal(x$lag_breaks, y$lag_breaks)
}

lag_of <- function(x, unit, period) {
  x$lag_panel$spatial_lag[x$lag_panel$id == unit & x$lag_panel$year == period]
}

test_that("geometry rows are matched to units by id", {
  fx <- nine_cell_fixture()
  ordered <- with_weights(fx$grid)
  shuffled <- with_weights(fx$grid[scramble(9), ])

  a <- spatial_markov(fx$panel, id, year, value, geometry = ordered, k = 3)
  b <- spatial_markov(fx$panel, id, year, value, geometry = shuffled, k = 3)

  # Unit "b" is the bottom-left cell. Its queen neighbors are units "g", "i",
  # and "a", with 2020 values 4, 8, and 11.
  expect_equal(lag_of(a, "b", 2020), (4 + 8 + 11) / 3)
  expect_same_dynamics(a, b)
})

test_that("geometry_id names the id column of geometry", {
  fx <- nine_cell_fixture()
  keyed <- with_weights(dplyr::rename(fx$grid[scramble(9), ], unit = "id"))

  a <- spatial_markov(fx$panel, id, year, value, geometry = with_weights(fx$grid), k = 3)
  b <- spatial_markov(fx$panel, id, year, value, geometry = keyed, geometry_id = unit, k = 3)
  c <- spatial_markov(fx$panel, id, year, value, geometry = keyed, geometry_id = "unit", k = 3)

  expect_same_dynamics(a, b)
  expect_same_dynamics(a, c)
})

test_that("listw and nb rows are matched by region id", {
  fx <- nine_cell_fixture()
  shuffled <- fx$grid[scramble(9), ]
  nb <- spdep::poly2nb(shuffled, queen = TRUE, row.names = shuffled$id)

  a <- spatial_markov(fx$panel, id, year, value, geometry = with_weights(fx$grid), k = 3)
  b <- spatial_markov(fx$panel, id, year, value, nb = nb, k = 3)
  c <- spatial_markov(fx$panel, id, year, value, listw = spdep::nb2listw(nb), k = 3)

  expect_same_dynamics(a, b)
  expect_same_dynamics(a, c)
})

test_that("shuffled usjoin geography gives the same results as sorted geography", {
  skip_if_not_installed("spData")
  data(us_states, package = "spData", envir = environment())

  states <- us_states[us_states$NAME %in% usjoin$name, ]
  sorted <- with_weights(states[order(states$NAME), ])
  shuffled <- with_weights(states[order(states$NAME), ][scramble(nrow(states)), ])

  a <- spatial_markov(usjoin, name, year, income, geometry = sorted, geometry_id = NAME, k = 5)
  b <- spatial_markov(usjoin, name, year, income, geometry = shuffled, geometry_id = NAME, k = 5)

  expect_same_dynamics(a, b)
})

test_that("weights without usable ids are matched by position, with a warning", {
  fx <- nine_cell_fixture()
  by_id <- spatial_markov(fx$panel, id, year, value, geometry = with_weights(fx$grid), k = 3)

  unkeyed <- with_weights(dplyr::select(fx$grid, -"id"))
  expect_warning(
    positional <- spatial_markov(fx$panel, id, year, value, geometry = unkeyed, k = 3),
    "`geometry` has no `id` column, so its rows were matched to units by position",
    fixed = TRUE
  )
  # Position follows ascending id, which is not the row order of `fx$grid`.
  expect_false(isTRUE(all.equal(
    positional$lag_panel$spatial_lag,
    by_id$lag_panel$spatial_lag
  )))

  sorted_unkeyed <- with_weights(dplyr::select(fx$grid[order(fx$grid$id), ], -"id"))
  expect_warning(
    sorted_positional <- spatial_markov(fx$panel, id, year, value, geometry = sorted_unkeyed, k = 3),
    "matched to units by position"
  )
  expect_same_dynamics(sorted_positional, by_id)

  # poly2nb() region ids default to row names, which are not the values of id.
  expect_warning(
    spatial_markov(fx$panel, id, year, value, nb = spdep::poly2nb(fx$grid), k = 3),
    "The region ids of `nb` do not match `id`",
    fixed = TRUE
  )
  expect_warning(
    spatial_markov(fx$panel, id, year, value, listw = spdep::nb2listw(spdep::poly2nb(fx$grid)), k = 3),
    "The region ids of `listw` do not match `id`",
    fixed = TRUE
  )
})

test_that("spatial_markov stops when geometry ids do not match the panel", {
  fx <- nine_cell_fixture()
  geom <- with_weights(fx$grid)

  renamed <- geom
  renamed$id[1] <- "z"
  expect_error(
    spatial_markov(fx$panel, id, year, value, geometry = renamed, k = 3),
    "1 value of `id` is not in `geometry$id`: \"b\".",
    fixed = TRUE
  )

  fewer_units <- fx$panel[fx$panel$id != "a", ]
  expect_error(
    spatial_markov(fewer_units, id, year, value, geometry = geom, k = 3),
    "1 value of `geometry$id` is not in `id`: \"a\".",
    fixed = TRUE
  )

  duplicated_id <- geom
  duplicated_id$id[2] <- duplicated_id$id[1]
  expect_error(
    spatial_markov(fx$panel, id, year, value, geometry = duplicated_id, k = 3),
    "`geometry$id` has duplicated values: \"b\".",
    fixed = TRUE
  )

  missing_id <- geom
  missing_id$id[1] <- NA
  expect_error(
    spatial_markov(fx$panel, id, year, value, geometry = missing_id, k = 3),
    "`geometry$id` has missing values.",
    fixed = TRUE
  )

  expect_error(
    spatial_markov(fx$panel, id, year, value, geometry = geom, geometry_id = unit, k = 3),
    "`geometry` has no column `unit`.",
    fixed = TRUE
  )

  nb <- spdep::poly2nb(fx$grid, row.names = fx$grid$id)
  expect_error(
    spatial_markov(fx$panel, id, year, value, nb = nb, geometry_id = id, k = 3),
    "`geometry_id` applies only to `geometry`.",
    fixed = TRUE
  )

  unbalanced <- fx$panel[-1, ]
  expect_error(
    spatial_markov(unbalanced, id, year, value, geometry = geom, k = 3),
    "Each time period must contain every unit exactly once.",
    fixed = TRUE
  )
})
