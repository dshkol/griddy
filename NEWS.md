# griddy 0.0.0.9000 (development)

Initial development release.

## Workflow

- `classify_dynamics()`, `markov_dynamics()`, `spatial_markov()`, and
  `rank_mobility()` accept long `sf` panels keyed by explicit `id`, `time`, and
  `value` columns.
- `transition_matrix()`, `steady_state()`, `class_intervals()`, and
  `lag_intervals()` provide tidy access to results.
- `plot_transition_matrix()`, `plot_spatial_markov()`, and
  `plot_rank_mobility()` return `ggplot2` objects.

## Data

- Bundled `usjoin`: 48 contiguous US state per-capita personal income,
  1929–2009, mirroring PySAL's reference dataset for spatial Markov examples.

## Validation

- Static fixtures cross-checked against `estdaR::sp.mkv()` and
  `spdyn::spMarkov()`. Optional live cross-checks run when those packages or
  PySAL `giddy` are installed.
