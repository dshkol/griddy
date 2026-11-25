# Estimate Stationary Distribution

Estimate Stationary Distribution

## Usage

``` r
steady_state(x)
```

## Arguments

- x:

  A `grd_markov` object or transition probability matrix.

## Value

A numeric vector.

## Examples

``` r
prob <- matrix(c(0.8, 0.2, 0.3, 0.7), nrow = 2, byrow = TRUE)
steady_state(prob)
#> [1] 0.6 0.4
```
