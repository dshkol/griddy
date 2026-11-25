# Plot A Transition Matrix

Plot A Transition Matrix

## Usage

``` r
plot_transition_matrix(x)
```

## Arguments

- x:

  A `grd_markov` object.

## Value

A `ggplot` object.

## Examples

``` r
panel <- data.frame(id = rep(1:4, each = 2), year = rep(2020:2021, 4), value = 1:8)
markov <- panel |>
  classify_dynamics(id, year, value, k = 2) |>
  markov_dynamics(id, year, class)

plot_transition_matrix(markov)
```
