# Extract A Transition Matrix

Extract A Transition Matrix

## Usage

``` r
transition_matrix(x, type = c("probability", "count"), lag_class = NULL)
```

## Arguments

- x:

  A `grd_markov` or `grd_spatial_markov` object.

- type:

  `"probability"` or `"count"`.

- lag_class:

  Optional lag class for `grd_spatial_markov`.

## Value

A matrix.

## Examples

``` r
panel <- data.frame(
  id = rep(letters[1:4], each = 3),
  year = rep(2020:2022, times = 4),
  value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
)
markov <- panel |>
  classify_dynamics(id, year, value, k = 3) |>
  markov_dynamics(id, year, class)

transition_matrix(markov, "count")
#>     
#>      Q1 Q2 Q3
#>   Q1  2  1  0
#>   Q2  0  2  1
#>   Q3  0  0  2
```
