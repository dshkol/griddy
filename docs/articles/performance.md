# Performance Benchmarks

Spatial Markov workflows often run on tract panels with thousands of
units and many periods. This article times `griddy` on a panel of that
size and compares it with `estdaR`. It runs when the site is built, not
during package checks.

``` r
library(griddy)
library(microbenchmark)
library(sf)
library(sfdep)
library(spdep)
library(dplyr)
library(tidyr)
```

## Synthetic grid panel

A 60 by 60 queen-contiguity grid over ten periods, 3,600 units in all,
exercises the same classification and spatial-lag code as a tract-scale
panel.

``` r
make_panel <- function(nx = 60, ny = 60, years = 2010:2019) {
  cells <- st_make_grid(st_bbox(c(xmin = 0, ymin = 0, xmax = nx, ymax = ny)), n = c(nx, ny))
  grid <- st_sf(id = seq_along(cells), geometry = cells)

  panel <- tidyr::crossing(id = grid$id, year = years) |>
    left_join(st_drop_geometry(grid), by = "id") |>
    mutate(value = id + as.integer(factor(year)) + rnorm(n())) |>
    left_join(select(grid, id, geometry), by = "id") |>
    st_as_sf()

  list(grid = grid, panel = panel)
}

fx <- make_panel()

geom <- fx$grid |>
  mutate(
    nb = st_contiguity(geometry),
    wt = st_weights(nb)
  )

listw <- nb2listw(geom$nb, glist = geom$wt, style = "W")

microbenchmark(
  classify = classify_dynamics(fx$panel, id, year, value, k = 5),
  markov = {
    cls <- classify_dynamics(fx$panel, id, year, value, k = 5)
    markov_dynamics(cls, id, year, class)
  },
  spatial = spatial_markov(fx$panel, id, year, value, geometry = geom, k = 5),
  times = 5
)
```

    ## Unit: milliseconds
    ##      expr      min       lq     mean   median       uq      max neval cld
    ##  classify 13.81212 14.12056 14.89371 14.79534 14.88677 16.85375     5 a  
    ##    markov 24.86511 24.96113 26.29378 26.40962 27.32232 27.91075     5  b 
    ##   spatial 38.68284 38.71601 40.38134 39.37472 40.89615 44.23699     5   c

## Comparison against estdaR

The next chunk runs only when `estdaR` is installed. It calls
[`griddy::spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
and [`estdaR::sp.mkv()`](https://rdrr.io/pkg/estdaR/man/sp.mkv.html) on
the same panel, with matched class breaks and identical weights, so any
difference is implementation overhead.

``` r
wide_panel <- fx$panel |>
  st_drop_geometry() |>
  pivot_wider(id_cols = id, names_from = year, values_from = value) |>
  arrange(id)

wide_mat <- as.matrix(wide_panel |> select(-id))

bench <- microbenchmark(
  griddy = spatial_markov(fx$panel, id, year, value, geometry = geom, k = 5),
  estdaR = estdaR::sp.mkv(wide_mat, listw, classes = 5, fixed = TRUE),
  times = 5
)
bench
```

    ## Unit: milliseconds
    ##    expr      min       lq     mean   median       uq      max neval cld
    ##  griddy 37.98437 38.04263 38.67189 39.00687 39.04090 39.28468     5  a 
    ##  estdaR 27.86606 28.27081 29.79210 30.14464 30.19859 32.48040     5   b

``` r
# griddy's median time as a multiple of estdaR's
medians <- summary(bench)$median
round(medians[1] / medians[2], 1)
```

    ## [1] 1.3

`griddy` is somewhat slower, and the gap is bookkeeping.
[`estdaR::sp.mkv()`](https://rdrr.io/pkg/estdaR/man/sp.mkv.html) works
directly on a unit-by-period matrix. `griddy` reshapes a long panel,
classifies it, and keeps unit, time, class, and spatial-lag labels
attached to every transition. Transition counts and spatial lags are
computed in single vectorized passes, with no per-unit or per-period
grouping.
