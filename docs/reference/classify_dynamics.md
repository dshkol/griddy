# Classify Longitudinal Values For Distribution Dynamics

Converts numeric values in a long panel into ordered classes suitable
for transition analysis.

## Usage

``` r
classify_dynamics(
  data,
  id,
  time,
  value,
  method = c("pooled_quantile", "time_quantile", "fixed", "existing"),
  k = 5,
  breaks = NULL,
  labels = NULL
)
```

## Arguments

- data:

  A data frame or `sf` object in long format.

- id, time, value:

  Columns identifying spatial unit, time, and value.

- method:

  Classification method. `"pooled_quantile"` uses one set of quantile
  breaks across all periods. `"time_quantile"` uses period-specific
  ranks. `"fixed"` uses user-supplied `breaks`. `"existing"` treats
  `value` as an already classified state.

- k:

  Number of quantile classes.

- breaks:

  Breaks for `method = "fixed"`.

- labels:

  Optional class labels.

## Value

A data frame or `sf` object with a `class` column and class
`grd_classes`.

## Examples

``` r
panel <- data.frame(
  id = rep(letters[1:4], each = 3),
  year = rep(2020:2022, times = 4),
  value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
)

classes <- classify_dynamics(panel, id, year, value, k = 3)
classes
#> <grd_classes>
#>    id year value class
#> 1   a 2020     8    Q1
#> 2   a 2021     9    Q1
#> 3   a 2022    11    Q1
#> 4   b 2020    10    Q1
#> 5   b 2021    12    Q2
#> 6   b 2022    13    Q2
#> 7   c 2020    15    Q2
#> 8   c 2021    14    Q2
#> 9   c 2022    16    Q3
#> 10  d 2020    20    Q3
#> 11  d 2021    22    Q3
#> 12  d 2022    25    Q3
class_intervals(classes)
#> # A tibble: 3 × 4
#>   class lower upper type 
#>   <ord> <dbl> <dbl> <chr>
#> 1 Q1      8    11.7 value
#> 2 Q2     11.7  15.3 value
#> 3 Q3     15.3  25   value
```
