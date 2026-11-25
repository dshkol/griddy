# Markov Mobility Indices

Computes scalar mobility indices summarizing how much movement a
transition probability matrix implies, following Formby, Smith, and
Zheng (2004) and mirroring `giddy.mobility.markov_mobility()` in PySAL
`giddy`.

## Usage

``` r
mobility_index(
  x,
  measure = c("prais", "determinant", "eigen", "bartholomew1", "bartholomew2"),
  initial = NULL
)
```

## Arguments

- x:

  A `grd_markov` object or a square transition probability matrix.

- measure:

  Character vector of indices to compute. Any of:

  - `"prais"`: the Prais–Shorrocks trace index,
    `(k - trace(P)) / (k - 1)`.

  - `"determinant"`: `1 - |det(P)|`.

  - `"eigen"`: the Sommers–Conlisk index, one minus the modulus of the
    second-largest eigenvalue of `P`.

  - `"bartholomew1"`: `(k - k * sum(initial * diag(P))) / (k - 1)`.

  - `"bartholomew2"`: the expected number of class boundaries crossed in
    one transition, `sum(initial[i] * P[i, j] * |i - j|) / (k - 1)`.
    Class distance uses the class ordering, so classes are assumed
    ordinal.

- initial:

  Optional initial distribution over classes used by the Bartholomew
  indices. Defaults to the uniform distribution, matching `giddy`.

## Value

A named numeric vector with one element per requested measure. All
indices are 0 for the identity matrix (no mobility) and increase with
mobility.

## Examples

``` r
prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
mobility_index(prob)
#>        prais  determinant        eigen bartholomew1 bartholomew2 
#>         0.30         0.30         0.30         0.30         0.15 
mobility_index(prob, measure = "prais")
#> prais 
#>   0.3 
```
