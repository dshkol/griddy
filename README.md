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
library(spData)
library(spdep)

data(usjoin)

geom <- us_states |>
  filter(NAME %in% usjoin$name) |>
  arrange(NAME)

panel <- usjoin |>
  filter(name %in% geom$NAME) |>
  arrange(name, year)

listw <- nb2listw(poly2nb(geom, queen = TRUE), style = "W")

classes <- classify_dynamics(panel, name, year, income, k = 5)
classic <- markov_dynamics(classes, name, year, class)
spatial <- spatial_markov(panel, name, year, income, listw = listw, k = 5)

classic$transitions |> select(id, from_time, to_time, transition) |> head()
lag_intervals(spatial)
```

`spatial_markov()` accepts either `listw` (a prebuilt `spdep` weights object)
or `nb` (a neighbor list, converted internally via
`spdep::nb2listw(style = "W")`). `listw` is preferred when the
row-standardization choice matters.

## Documentation

The pkgdown site is organized around:

- core workflow and concepts
- `tidycensus` and `cancensus` templates
- prior-art comparison against `estdaR` and `spdyn`
- performance benchmarking notes
