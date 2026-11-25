# Expected Sojourn Times

Computes the expected number of consecutive periods a unit remains in
each class once it enters it, `1 / (1 - p_ii)`. Absorbing classes
(`p_ii = 1`) have infinite sojourn times.

## Usage

``` r
sojourn_time(x)
```

## Arguments

- x:

  A `grd_markov` object or a square transition probability matrix.

## Value

A named numeric vector of expected sojourn times, one per class.

## Examples

``` r
prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
sojourn_time(prob)
#> [1] 10  5
```
