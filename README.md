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

The minimal example below also uses `spData` for state geometry:

```r
install.packages("spData")
```

## What it does

`griddy` keeps the workflow keyed by explicit `id`, `time`, and `value`
columns instead of matrix row position. The analytical outputs preserve
transition labels, class intervals, and spatial-lag intervals so they can be
inspected, joined, and plotted without reverse-engineering array dimensions.

## Minimal example

The bundled `usjoin` panel is the canonical PySAL `giddy` reference dataset:
48 contiguous US states, per-capita personal income, 1929 to 2009.

```r
library(griddy)
library(dplyr)
library(sf)
library(sfdep)
library(spData)

data(usjoin)

geom <- us_states |>
  filter(NAME %in% usjoin$name) |>
  arrange(NAME) |>
  mutate(
    nb = st_contiguity(geometry),
    wt = st_weights(nb)
  )

panel <- usjoin |>
  filter(name %in% geom$NAME) |>
  arrange(name, year)

classes <- classify_dynamics(panel, name, year, income, k = 5)
classic <- markov_dynamics(classes, name, year, class)
spatial <- spatial_markov(panel, name, year, income, geometry = geom, k = 5)

classic$transitions |> select(id, from_time, to_time, transition) |> head()
lag_intervals(spatial)
```

`spatial_markov()` takes a `geometry` argument: an `sf` tibble with one row
per spatial unit and `nb` / `wt` list-columns produced by `sfdep`. This keeps
the spatial frame, neighbor structure, and row-standardization choice in one
tidy object. `listw` and `nb` arguments remain accepted for compatibility with
existing workflows.

## Documentation

The pkgdown site is organized around:

- core workflow and concepts
- `tidycensus` and `cancensus` templates
- prior-art comparison against `estdaR` and `spdyn`
- performance benchmarking notes
