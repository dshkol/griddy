# Usage Guide for LLMs and Agents

This page is for language models and coding agents that use `griddy` on
behalf of a user. It states the current API exactly, including the
functions added in 0.2.0, which may postdate your training data. A
machine-readable index of this site is at
[`llms.txt`](https://dshkol.github.io/griddy/llms.txt). Every page also
has a Markdown version at the same address, with `.md` in place of
`.html`.

## What this package is

`griddy` measures how values in a spatial panel move between classes
over time. It estimates classic and spatial Markov chains, summarizes
them, tests whether transition dynamics differ across regimes, and
measures rank mobility. Inputs are long data frames or `sf` objects.
Outputs are tidy tables, S3 objects with print methods, and `ggplot2`
plots. The methods follow Rey (2001) and Rey, Kang, and Wolf (2016).
PySAL `giddy` is the Python reference implementation; [Coverage of PySAL
giddy](https://dshkol.github.io/griddy/articles/giddy-coverage.md) maps
each of its features to a `griddy` function, a short recipe, or another
package.

## Input shape

One row per unit per period. `id`, `time`, and `value` are bare column
names (tidy evaluation), not strings.

For spatial Markov, pass `geometry`: an `sf` tibble with one row per
unit, taken from a single period, carrying `nb` and `wt` list-columns
from `sfdep`. Its rows are matched to units by id: through a column with
the same name as `id`, or through the column named in `geometry_id`.
`listw` and `nb` arguments are accepted for older code; prefer
`geometry`.

``` r
geom <- geography |>
  dplyr::mutate(
    nb = sfdep::st_contiguity(geometry),
    wt = sfdep::st_weights(nb)
  )
```

## Functions

These are the exported functions in `griddy` 0.2.0, with their exact
signatures.

``` r
# Classification and chains
classify_dynamics(data, id, time, value,
  method = c("pooled_quantile", "time_quantile", "fixed", "existing"),
  k = 5, breaks = NULL, labels = NULL)
markov_dynamics(classes, id, time, state = class)
spatial_markov(data, id, time, value,
  geometry = NULL, geometry_id = NULL, listw = NULL, nb = NULL,
  k = 5, lag_k = k,
  class_method = c("pooled_quantile", "time_quantile", "fixed"),
  zero.policy = TRUE)
transition_matrix(x, type = c("probability", "count"), lag_class = NULL)
class_intervals(x, ...)
lag_intervals(x)

# Chain summaries (x is a grd_markov object or a probability matrix)
steady_state(x)
sojourn_time(x)       # new in 0.2.0
first_passage(x)      # new in 0.2.0
mobility_index(x,     # new in 0.2.0
  measure = c("prais", "determinant", "eigen", "bartholomew1", "bartholomew2"),
  initial = NULL)

# Inference (x is a grd_spatial_markov object or a list of count matrices)
homogeneity_test(x, ...)  # new in 0.2.0

# Rank mobility and plots
rank_mobility(data, id, time, value,
  compare = c("endpoint", "adjacent"), descending = TRUE)
plot_transition_matrix(x)
plot_spatial_markov(x)
plot_rank_mobility(x)
```

What each one returns:

- [`classify_dynamics()`](https://dshkol.github.io/griddy/reference/classify_dynamics.md):
  the input with an ordered `class` column, as a `grd_classes` object.
- [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md):
  a `grd_markov` object with `transitions` (one row per unit and step)
  and `matrix` (one row per cell).
- [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md):
  a `grd_spatial_markov` object. `transitions` adds `lag_class` and
  `spatial_lag`. `matrix` is keyed by `lag_class`, `from_state`, and
  `to_state`.
- [`transition_matrix()`](https://dshkol.github.io/griddy/reference/transition_matrix.md):
  a base matrix. With `lag_class`, the conditional matrix for that
  spatial-lag class.
- [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md),
  [`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md):
  named numeric vectors.
  [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md):
  a matrix.
- [`mobility_index()`](https://dshkol.github.io/griddy/reference/mobility_index.md):
  a named vector with all five measures by default.
- [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md):
  a tibble with columns `test`, `statistic`, `df`, and `p_value`, and
  rows `chi2`, `likelihood_ratio`, and `kullback`.
- [`rank_mobility()`](https://dshkol.github.io/griddy/reference/rank_mobility.md):
  the input with ranks added. Endpoint comparisons add `start_time`,
  `end_time`, `start_rank`, and `end_rank`; adjacent comparisons add
  `to_time` and `to_rank`. Both add `rank_change` and `abs_rank_change`.

## A complete workflow

The bundled `usjoin` panel has per-capita income for 48 US states from
1929 to 2009.

``` r
library(griddy)
library(dplyr)
library(sf)
library(sfdep)

data(usjoin)
data(us_states, package = "spData")

geom <- us_states |>
  filter(NAME %in% usjoin$name) |>
  mutate(nb = st_contiguity(geometry), wt = st_weights(nb))

relative <- usjoin |>
  group_by(year) |>
  mutate(rel_income = income / mean(income)) |>
  ungroup()

chain <- relative |>
  classify_dynamics(name, year, rel_income, k = 5) |>
  markov_dynamics(name, year, class)

sojourn_time(chain)
#>        Q1        Q2        Q3        Q4        Q5 
#> 11.712121  5.765152  4.860759  6.603448 16.083333
mobility_index(chain, "prais")
#>     prais 
#> 0.1695447

spatial <- spatial_markov(
  relative, name, year, rel_income,
  geometry = geom, geometry_id = NAME, k = 5
)
homogeneity_test(spatial)
#> # A tibble: 3 × 4
#>   test             statistic    df  p_value
#>   <chr>                <dbl> <int>    <dbl>
#> 1 chi2                  201.    60 4.72e-17
#> 2 likelihood_ratio      171.    60 1.49e-12
#> 3 kullback              171.    60 1.49e-12
```

## Pitfalls

- **Give the weights ids.**
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  matches the rows of `geometry` to units through a column with the same
  name as `id`, or through the column named in `geometry_id`, so row
  order does not matter. For `listw` or `nb`, it uses the region ids
  when they are the values of `id`; set them with
  `spdep::poly2nb(x, row.names = x$id)`. Without usable ids it matches
  rows by position, in ascending order of `id`, and warns. Do not ignore
  that warning: weights in any other row order give units the wrong
  neighbors. Before 0.2.0, rows were always matched by position, with no
  warning.
- **Build `nb` and `wt` last.** They refer to rows of `geometry` by
  position. Filtering or reordering `geometry` after building them gives
  units the wrong neighbors, and matching by id cannot detect it.
- **Balance the panel for spatial Markov.** Every unit must appear in
  every period, and the weights must cover exactly the panel’s units;
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  stops otherwise.
- **Use relative values for chain summaries.** With pooled breaks on a
  growing nominal series, units drift into the top class and stay there.
  The chain becomes absorbing:
  [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md)
  puts all mass in the top class,
  [`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md)
  returns `Inf`, and
  [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md)
  stops with an error. Divide by the period mean or median before
  classifying, as in the workflow above.
- **[`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md)
  needs an irreducible chain**: every class reachable from every other.
- **Empty rows are `NA`.** A class with no departures has `NA`
  probabilities, not zeros, and zero counts. Conditional matrices for
  spatial-lag classes often have such rows. The coverage article shows
  how to fill them the way giddy’s `fill_empty_classes` does.
- **Lag classes are measured at the start of each transition**, from the
  spatial lag in `from_time`.
- **`kullback` equals `likelihood_ratio`.** With origin-state margins
  the two statistics are identical, and both use the Bickenbach and
  Bode (2003) degrees of freedom. Do not report them as independent
  evidence.
- **Pass counts, not probabilities, to
  [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md).**
  For regimes other than spatial-lag classes, pass a list of count
  matrices with the same dimensions.
- **Rank direction.** With `descending = TRUE` (the default), the
  largest value has rank 1, and a positive `rank_change` means a unit
  moved up.

## What griddy does not do

- Full and geographic rank Markov chains, the Kendall’s tau family
  including LIMA, and rose diagrams are planned. The coverage article
  has recipes for the rank chains with existing functions.
- Sequence analysis is out of scope; use
  [`TraMineR`](https://CRAN.R-project.org/package=TraMineR).
- Communicating, recurrent, and absorbing class analysis of reducible
  chains is out of scope; use
  [`markovchain`](https://CRAN.R-project.org/package=markovchain).

## References

Bickenbach, F., and Bode, E. (2003). Evaluating the Markov property in
studies of economic convergence. *International Regional Science
Review*, 26(3), 363–392. <https://doi.org/10.1177/0160017603253789>

Rey, S. J. (2001). Spatial empirics for economic growth and convergence.
*Geographical Analysis*, 33(3), 195–214.
<https://doi.org/10.1111/j.1538-4632.2001.tb00444.x>

Rey, S. J., Kang, W., and Wolf, L. (2016). The properties of tests for
spatial effects in discrete Markov chain models of regional income
distribution dynamics. *Journal of Geographical Systems*, 18(4),
377–398. <https://doi.org/10.1007/s10109-016-0234-x>
