# Development performance benchmark. Excluded from package build.

library(dplyr)
library(griddy)
library(microbenchmark)
library(sf)
library(spdep)
library(tidyr)

make_panel <- function(nx = 50, ny = 50, years = 2010:2019) {
  grid <- st_make_grid(st_bbox(c(xmin = 0, ymin = 0, xmax = nx, ymax = ny)), n = c(nx, ny)) |>
    st_as_sf() |>
    mutate(id = row_number())

  panel <- tidyr::crossing(id = grid$id, year = years) |>
    mutate(value = id + as.integer(factor(year)) + rnorm(n())) |>
    left_join(select(grid, id, geometry), by = "id") |>
    st_as_sf()

  list(grid = grid, panel = panel, nb = cell2nb(nx, ny, type = "queen"))
}

fx <- make_panel()

microbenchmark(
  classify = classify_dynamics(fx$panel, id, year, value, k = 5),
  classic = {
    cls <- classify_dynamics(fx$panel, id, year, value, k = 5)
    markov_dynamics(cls, id, year, class)
  },
  spatial = spatial_markov(fx$panel, id, year, value, nb = fx$nb, k = 5),
  times = 10
)
