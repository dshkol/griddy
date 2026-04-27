# griddy

`griddy` is an experimental R package for geospatial distribution dynamics
with `sf` and tidy data. It is inspired by PySAL `giddy` and by established
spatial distribution dynamics work, especially Rey (2001).

This is not a methods-novelty project. Prior R implementations exist,
including `estdaR` and `spdyn`. The package target is a maintained,
CRAN-grade, long-data, map-ready workflow.

Current scope:

- classify longitudinal spatial values into comparable classes
- estimate classic Markov transition matrices
- estimate spatial Markov transition matrices conditioned on spatial lag class
- compute simple rank mobility
- return tidy tables and `ggplot2` plots

The API and scope are still provisional.

## Installation

```r
# install.packages("pak")
pak::pak("dshkol/griddy")
```

## What it does

`griddy` keeps the workflow keyed by explicit `id`, `time`, and `value`
columns instead of matrix row position. The analytical outputs preserve
transition labels, class intervals, and spatial-lag intervals so they can be
inspected, joined, and plotted without reverse-engineering array dimensions.

## Minimal example

```r
library(griddy)
library(dplyr)
library(spData)
library(spdep)
library(tidyr)

data(us_states, package = "spData")
data(us_states_df, package = "spData")

states <- us_states |>
  left_join(us_states_df, by = c("NAME" = "state")) |>
  filter(!NAME %in% c("Alaska", "Hawaii", "Puerto Rico")) |>
  arrange(NAME)

panel <- states |>
  select(NAME, median_income_10, median_income_15, geometry) |>
  pivot_longer(starts_with("median_income_"), names_to = "year", values_to = "income") |>
  mutate(year = if_else(year == "median_income_10", 2010L, 2015L))

nb <- poly2nb(states, queen = TRUE)

classes <- classify_dynamics(panel, NAME, year, income, k = 5)
classic <- markov_dynamics(classes, NAME, year, class)
spatial <- spatial_markov(panel, NAME, year, income, nb = nb, k = 5)

classic$transitions |> select(id, from_time, to_time, transition) |> head()
lag_intervals(spatial)
```

## Documentation

The pkgdown site is organized around:

- core workflow and concepts
- `tidycensus` and `cancensus` templates
- prior-art comparison against `estdaR` and `spdyn`
- performance benchmarking notes
