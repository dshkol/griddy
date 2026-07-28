# griddy (development version)

## New features

- `sojourn_time()`, `first_passage()`, and `mobility_index()` compute expected
  sojourn times, Kemeny--Snell mean first-passage times, and scalar Markov
  mobility indices (Prais--Shorrocks, determinant, Sommers--Conlisk
  eigenvalue, and both Bartholomew indices) from `grd_markov` objects or raw
  transition probability matrices. Results are validated against PySAL
  `giddy` (`ergodic.mfpt`, `markov.sojourn_time`,
  `mobility.markov_mobility`) via static fixtures.

# griddy 0.1.1

## Performance

- `spatial_markov()`, `markov_dynamics()`, and `rank_mobility(compare =
  "adjacent")` replace per-unit grouped `dplyr::lead()` calls with a
  vectorized within-group shift, and `spatial_markov()` computes spatial lags
  with a single matrix `spdep::lag.listw()` call instead of one call per
  period. On a 3,600-unit, 10-period panel `spatial_markov()` runs about 4x
  faster. Outputs are unchanged.

# griddy 0.1.0

Initial CRAN release.

## Workflow

- `classify_dynamics()`, `markov_dynamics()`, `spatial_markov()`, and
  `rank_mobility()` accept long `sf` panels keyed by explicit `id`, `time`, and
  `value` columns.
- `transition_matrix()`, `steady_state()`, `class_intervals()`, and
  `lag_intervals()` provide tidy access to results.
- `plot_transition_matrix()`, `plot_spatial_markov()`, and
  `plot_rank_mobility()` return `ggplot2` objects.

## Spatial weights

- `spatial_markov()` accepts a `geometry` argument: an `sf` tibble with one
  row per spatial unit and `nb` / `wt` list-columns produced by `sfdep`. This
  is the preferred input. `listw` and `nb` arguments remain accepted for
  compatibility with prior workflows and oracle comparisons.

## Data

- Bundled `usjoin`: 48 contiguous US state per-capita personal income,
  1929–2009, mirroring PySAL's reference dataset for spatial Markov examples.

## Validation

- Static fixtures cross-checked against `estdaR::sp.mkv()` and
  `spdyn::spMarkov()`. Optional live cross-checks run when those packages or
  PySAL `giddy` are installed.
