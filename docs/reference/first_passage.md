# Mean First-Passage Times

Computes the matrix of mean first-passage times for an ergodic
transition probability matrix following Kemeny and Snell: entry `[i, j]`
is the expected number of transitions to reach class `j` for the first
time starting from class `i`. Diagonal entries are mean recurrence
times, the reciprocal of the stationary distribution.

## Usage

``` r
first_passage(x)
```

## Arguments

- x:

  A `grd_markov` object or a square transition probability matrix. The
  underlying chain must be irreducible; periodic chains are supported,
  while matrices with absorbing or unreachable classes are rejected.

## Value

A square numeric matrix of mean first-passage times.

## Examples

``` r
prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
first_passage(prob)
#>      [,1] [,2]
#> [1,]  1.5   10
#> [2,]  5.0    3
```
