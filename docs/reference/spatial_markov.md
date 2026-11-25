# Estimate Spatial Markov Transition Dynamics

Estimates transition matrices conditioned on the class of each unit's
spatial lag at the start of the transition period.

## Usage

``` r
spatial_markov(
  data,
  id,
  time,
  value,
  geometry = NULL,
  listw = NULL,
  nb = NULL,
  k = 5,
  lag_k = k,
  class_method = c("pooled_quantile", "time_quantile", "fixed"),
  zero.policy = TRUE
)
```

## Arguments

- data:

  A long data frame or `sf` object.

- id, time, value:

  Columns identifying spatial unit, time, and value.

- geometry:

  An `sf` tibble with one row per spatial unit (a single time slice's
  geography), carrying `nb` and `wt` list-columns produced by
  [`sfdep::st_contiguity()`](https://rdrr.io/pkg/sfdep/man/st_contiguity.html)
  and
  [`sfdep::st_weights()`](https://rdrr.io/pkg/sfdep/man/st_weights.html).
  The preferred input.

- listw:

  A row-standardized `spdep` `listw` object. Accepted for compatibility
  with prior workflows; use `geometry` for new code.

- nb:

  A `spdep` neighbor list, used only when both `geometry` and `listw`
  are `NULL`. Converted with `spdep::nb2listw(style = "W")`.

- k:

  Number of value classes.

- lag_k:

  Number of spatial-lag classes.

- class_method:

  Value classification method passed to
  [`classify_dynamics()`](https://dshkol.github.io/griddy/reference/classify_dynamics.md).

- zero.policy:

  Passed to `spdep` lag/weight helpers.

## Value

A `grd_spatial_markov` object.

## Examples

``` r
panel <- data.frame(
  id = rep(1:4, each = 3),
  year = rep(2020:2022, times = 4),
  value = c(1, 2, 3, 2, 3, 4, 4, 3, 5, 5, 6, 7)
)

grid <- sf::st_sf(
  id = 1:4,
  geometry = sf::st_make_grid(
    sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 2, ymax = 2)),
    n = c(2, 2)
  )
) |>
  dplyr::mutate(
    nb = sfdep::st_contiguity(geometry),
    wt = sfdep::st_weights(nb)
  )

spatial <- spatial_markov(panel, id, year, value, geometry = grid, k = 2)

spatial
#> <grd_spatial_markov>
#> 2 states, 2 lag states, 8 observed transitions
#> # A tibble: 8 × 8
#>   lag_class from_state to_state transition     n probability lag_lower lag_upper
#>   <ord>     <ord>      <ord>    <chr>      <int>       <dbl>     <dbl>     <dbl>
#> 1 Q1        Q1         Q1       Q1 -> Q1       2       0.5        2.33      3.67
#> 2 Q1        Q1         Q2       Q1 -> Q2       2       0.5        2.33      3.67
#> 3 Q1        Q2         Q1       Q2 -> Q1       1       0.333      2.33      3.67
#> 4 Q1        Q2         Q2       Q2 -> Q2       2       0.667      2.33      3.67
#> 5 Q2        Q1         Q1       Q1 -> Q1       1       1          3.67      5.33
#> 6 Q2        Q1         Q2       Q1 -> Q2       0       0          3.67      5.33
#> 7 Q2        Q2         Q1       Q2 -> Q1       0      NA          3.67      5.33
#> 8 Q2        Q2         Q2       Q2 -> Q2       0      NA          3.67      5.33
lag_intervals(spatial)
#> # A tibble: 2 × 4
#>   class lower upper type       
#>   <ord> <dbl> <dbl> <chr>      
#> 1 Q1     2.33  3.67 spatial_lag
#> 2 Q2     3.67  5.33 spatial_lag
transition_matrix(spatial, "count", lag_class = "Q1")
#>    Q1 Q2
#> Q1  2  2
#> Q2  1  2
```
