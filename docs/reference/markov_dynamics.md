# Estimate Classic Markov Transition Dynamics

Estimates transition counts and probabilities between adjacent periods
for a classified long panel.

## Usage

``` r
markov_dynamics(classes, id, time, state = class)
```

## Arguments

- classes:

  A classified data frame from
  [`classify_dynamics()`](https://dshkol.github.io/griddy/reference/classify_dynamics.md)
  or any data frame with ID, time, and state columns.

- id, time, state:

  Columns identifying spatial unit, time, and state.

## Value

A `grd_markov` object.

## Examples

``` r
panel <- data.frame(
  id = rep(letters[1:4], each = 3),
  year = rep(2020:2022, times = 4),
  value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
)

classes <- classify_dynamics(panel, id, year, value, k = 3)
markov <- markov_dynamics(classes, id, year, class)

markov
#> <grd_markov>
#> 3 states, 8 observed transitions
#>     
#>             Q1        Q2        Q3
#>   Q1 0.6666667 0.3333333 0.0000000
#>   Q2 0.0000000 0.6666667 0.3333333
#>   Q3 0.0000000 0.0000000 1.0000000
transition_matrix(markov)
#>     
#>             Q1        Q2        Q3
#>   Q1 0.6666667 0.3333333 0.0000000
#>   Q2 0.0000000 0.6666667 0.3333333
#>   Q3 0.0000000 0.0000000 1.0000000
steady_state(markov)
#> Q1 Q2 Q3 
#>  0  0  1 
```
