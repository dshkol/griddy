# Changelog

## griddy 0.2.0

### New features

- [`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md),
  [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md),
  and
  [`mobility_index()`](https://dshkol.github.io/griddy/reference/mobility_index.md)
  compute expected sojourn times, Kemeny–Snell mean first-passage times,
  and scalar Markov mobility indices (Prais–Shorrocks, determinant,
  Sommers–Conlisk eigenvalue, and both Bartholomew indices) from
  `grd_markov` objects or raw transition probability matrices. Static
  fixtures validate results against PySAL `giddy` (`ergodic.mfpt`,
  `markov.sojourn_time`, `mobility.markov_mobility`).

- [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md)
  tests whether transition dynamics differ across regimes. For
  `grd_spatial_markov` objects, it tests whether the matrices
  conditioned on spatial-lag class differ from the pooled matrix (Rey,
  Kang, and Wolf 2016). It reports the Pearson chi-squared Q and
  likelihood-ratio tests with the Bickenbach–Bode (2003)
  degrees-of-freedom adjustment and the Kullback (1962) information
  test. Static fixtures validate the first two against PySAL `giddy`.
  The Kullback statistic uses the origin-state margins required by the
  conditional likelihood, which makes it identical to the
  likelihood-ratio statistic, and it shares the Bickenbach–Bode degrees
  of freedom. It therefore differs from `giddy.markov.kullback()`
  through giddy 2.3.9, which uses terminal-state margins (fixed upstream
  in [giddy PR 260](https://github.com/pysal/giddy/pull/260)) and
  unadjusted degrees of freedom (see [giddy issue
  265](https://github.com/pysal/giddy/issues/265)). A list method
  accepts arbitrary regime count matrices.

### Bug fixes

- [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  matched the rows of `geometry`, `listw`, or `nb` to units by position,
  assuming they were in ascending order of `id`. Weights in any other
  row order gave units the wrong neighbors, and no error was raised.
  This dates from 0.1.0. Rows are now matched by id: through a
  `geometry` column with the same name as `id`, through the column named
  in the new `geometry_id` argument, or through the region ids of
  `listw` and `nb`.
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  stops when those ids are missing, duplicated, or do not match the
  panel. When the weights carry no usable ids, it still matches by
  position and now warns. Results for weights sorted by `id` are
  unchanged.

### Documentation

- New article, “Coverage of PySAL giddy”, maps every public entry of
  giddy 2.3.9 to a `griddy` function, a short recipe, a planned feature,
  or another package.

- The Get Started vignette covers the chain summaries and homogeneity
  tests.

- New article, “Usage Guide for LLMs and Agents”, gives language models
  and coding agents the exact current API, the common pitfalls, and what
  `griddy` does not cover.

- The website now publishes `llms.txt`, an index for language models,
  and a Markdown version of every page.

- The GitHub repository includes an `AGENTS.md` with guidance for AI
  coding agents contributing to `griddy`. It is not part of the
  installed package.

## griddy 0.1.1

This version was tagged on GitHub but not released to CRAN. Its changes
reach CRAN in 0.2.0.

### Performance

- [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md),
  [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md),
  and `rank_mobility(compare = "adjacent")` replace per-unit grouped
  [`dplyr::lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html)
  calls with a vectorized within-group shift, and
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  computes spatial lags with a single matrix
  [`spdep::lag.listw()`](https://r-spatial.github.io/spdep/reference/lag.listw.html)
  call instead of one call per period. On a 3,600-unit, 10-period panel
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  runs about 4x faster. Outputs are unchanged.

## griddy 0.1.0

CRAN release: 2026-05-30

Initial CRAN release.

### Workflow

- [`classify_dynamics()`](https://dshkol.github.io/griddy/reference/classify_dynamics.md),
  [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md),
  [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md),
  and
  [`rank_mobility()`](https://dshkol.github.io/griddy/reference/rank_mobility.md)
  accept long `sf` panels keyed by explicit `id`, `time`, and `value`
  columns.
- [`transition_matrix()`](https://dshkol.github.io/griddy/reference/transition_matrix.md),
  [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md),
  [`class_intervals()`](https://dshkol.github.io/griddy/reference/class_intervals.md),
  and
  [`lag_intervals()`](https://dshkol.github.io/griddy/reference/lag_intervals.md)
  provide tidy access to results.
- [`plot_transition_matrix()`](https://dshkol.github.io/griddy/reference/plot_transition_matrix.md),
  [`plot_spatial_markov()`](https://dshkol.github.io/griddy/reference/plot_spatial_markov.md),
  and
  [`plot_rank_mobility()`](https://dshkol.github.io/griddy/reference/plot_rank_mobility.md)
  return `ggplot2` objects.

### Spatial weights

- [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
  accepts a `geometry` argument: an `sf` tibble with one row per spatial
  unit and `nb` / `wt` list-columns produced by `sfdep`. This is the
  preferred input. `listw` and `nb` arguments remain accepted for
  compatibility with prior workflows and oracle comparisons.

### Data

- Bundled `usjoin`: 48 contiguous US state per-capita personal income,
  1929–2009, mirroring PySAL’s reference dataset for spatial Markov
  examples.

### Validation

- Static fixtures cross-checked against
  [`estdaR::sp.mkv()`](https://rdrr.io/pkg/estdaR/man/sp.mkv.html) and
  `spdyn::spMarkov()`. Optional live cross-checks run when those
  packages or PySAL `giddy` are installed.
