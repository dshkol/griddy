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
  geometry_id = NULL,
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
  The preferred input. Its rows are matched to units by the
  `geometry_id` column, or by a column with the same name as `id`, so
  their order does not matter.

- geometry_id:

  The column of `geometry` that holds unit ids, when its name differs
  from `id`. Its values must match the values of `id` one to one.

- listw:

  A row-standardized `spdep` `listw` object. Accepted for compatibility
  with prior workflows; use `geometry` for new code. Its rows are
  matched to units by id when its region ids are the values of `id`, as
  with `spdep::poly2nb(x, row.names = x$id)`, and by position otherwise.

- nb:

  A `spdep` neighbor list, used only when both `geometry` and `listw`
  are `NULL`. Converted with `spdep::nb2listw(style = "W")`. Its rows
  are matched to units as for `listw`.

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

## Matching weights to units

Each row of `geometry`, `listw`, or `nb` describes one unit. The
neighbor lists refer to rows by position, so build them after the last
filter or reorder of the geography. `spatial_markov()` matches rows to
the units in `data` by id, and the row order of the weights does not
matter. It stops when the weights' ids have missing or duplicated values
or do not match the values of `id` one to one.

When the weights carry no usable ids, rows are matched by position: the
first row is taken to be the unit with the smallest `id`, the second row
the next, and so on. This happens when `geometry` has neither a
`geometry_id` column nor a column named like `id`, and when the region
ids of `listw` or `nb` are not the values of `id`. `spatial_markov()`
warns in that case, because weights in any other row order give units
the wrong neighbors without an error. Before griddy 0.2.0, rows were
always matched by position.

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
