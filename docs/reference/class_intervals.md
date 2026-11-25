# Class Intervals Used By A griddy Object

Class Intervals Used By A griddy Object

## Usage

``` r
class_intervals(x, ...)
```

## Arguments

- x:

  A griddy result object.

- ...:

  Reserved for future methods.

## Value

A tibble of class intervals when available.

## Examples

``` r
panel <- data.frame(id = rep(1:3, each = 2), year = rep(2020:2021, 3), value = 1:6)
classes <- classify_dynamics(panel, id, year, value, k = 3)
class_intervals(classes)
#> # A tibble: 3 × 4
#>   class lower upper type 
#>   <ord> <dbl> <dbl> <chr>
#> 1 Q1     1     2.67 value
#> 2 Q2     2.67  4.33 value
#> 3 Q3     4.33  6    value
```
