# Compute Rank Mobility

Computes simple rank changes for map-ready exploratory analysis.

## Usage

``` r
rank_mobility(
  data,
  id,
  time,
  value,
  compare = c("endpoint", "adjacent"),
  descending = TRUE
)
```

## Arguments

- data:

  A long data frame or `sf` object.

- id, time, value:

  Columns identifying spatial unit, time, and value.

- compare:

  `"endpoint"` compares first and last observed periods per unit.
  `"adjacent"` compares adjacent periods.

- descending:

  If `TRUE`, larger values receive better ranks.

## Value

A `grd_rank_mobility` data frame or `sf` object.

## Examples

``` r
panel <- data.frame(
  id = rep(letters[1:4], each = 3),
  year = rep(2020:2022, times = 4),
  value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
)

rank_mobility(panel, id, year, value)
#> <grd_rank_mobility>
#> # A tibble: 4 × 10
#>   id     year value  rank start_time end_time start_rank end_rank rank_change
#>   <chr> <int> <dbl> <int>      <int>    <int>      <int>    <int>       <int>
#> 1 a      2022    11     4       2020     2022          4        4           0
#> 2 b      2022    13     3       2020     2022          3        3           0
#> 3 c      2022    16     2       2020     2022          2        2           0
#> 4 d      2022    25     1       2020     2022          1        1           0
#> # ℹ 1 more variable: abs_rank_change <int>
```
