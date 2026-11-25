# Working With tidycensus

``` r
library(griddy)
library(dplyr)
library(tidyr)
```

This article runs the core `griddy` workflow on census tracts in San
Francisco, using median household income (ACS table B19013) from three
five-year American Community Survey samples: 2008–2012, 2013–2017, and
2018–2022. The samples do not overlap, so each tract contributes two
transitions. The article needs a Census API key. It renders on the
pkgdown site when one is set and does not ship with the package.

``` r
library(tidycensus)
library(sf)
```

    ## Warning: package 'sf' was built under R version 4.5.2

    ## Linking to GEOS 3.13.0, GDAL 3.8.5, PROJ 9.5.1; sf_use_s2() is TRUE

``` r
library(sfdep)

years <- c(2012, 2017, 2022)

acs <- purrr::map_dfr(years, function(y) {
  get_acs(
    geography = "tract",
    variables = "B19013_001",
    state = "CA",
    county = "San Francisco",
    year = y,
    survey = "acs5",
    geometry = TRUE
  ) |>
    transmute(
      GEOID,
      year = y,
      median_income = estimate,
      geometry
    ) |>
    filter(is.finite(median_income))
})
```

    ## Getting data from the 2008-2012 5-year ACS

    ## Downloading feature geometry from the Census website.  To cache shapefiles for use in future sessions, set `options(tigris_use_cache = TRUE)`.

    ## Getting data from the 2013-2017 5-year ACS

    ## Downloading feature geometry from the Census website.  To cache shapefiles for use in future sessions, set `options(tigris_use_cache = TRUE)`.

    ## Getting data from the 2018-2022 5-year ACS

    ## Downloading feature geometry from the Census website.  To cache shapefiles for use in future sessions, set `options(tigris_use_cache = TRUE)`.

``` r
geography <- acs |>
  filter(year == max(year)) |>
  filter(!st_is_empty(geometry)) |>
  arrange(GEOID)

common_ids <- acs |>
  st_drop_geometry() |>
  count(GEOID) |>
  filter(n == length(years)) |>
  pull(GEOID) |>
  intersect(geography$GEOID)

panel <- acs |>
  filter(GEOID %in% common_ids) |>
  st_drop_geometry() |>
  left_join(select(geography, GEOID, geometry), by = "GEOID") |>
  st_as_sf()

geography <- geography |>
  filter(GEOID %in% common_ids) |>
  arrange(GEOID) |>
  mutate(
    nb = st_contiguity(geometry, queen = TRUE),
    wt = st_weights(nb, allow_zero = TRUE)
  )
```

    ## Warning: There was 1 warning in `stopifnot()`.
    ## ℹ In argument: `nb = st_contiguity(geometry, queen = TRUE)`.
    ## Caused by warning in `spdep::poly2nb()`:
    ## ! neighbour object has 2 sub-graphs;
    ## if this sub-graph count seems unexpected, try increasing the snap argument.

``` r
classes <- classify_dynamics(panel, GEOID, year, median_income, k = 5)
classic <- markov_dynamics(classes, GEOID, year, class)
spatial <- spatial_markov(panel, GEOID, year, median_income, geometry = geography, k = 5)
mobility <- rank_mobility(panel, GEOID, year, median_income)

plot_transition_matrix(classic)
```

![Heatmap of ACS tract transition probabilities between income
quintiles.](tidycensus-workflows_files/figure-html/unnamed-chunk-2-1.png)

``` r
plot_spatial_markov(spatial)
```

![Faceted heatmaps of ACS tract spatial Markov transition probabilities
by spatial-lag
quintile.](tidycensus-workflows_files/figure-html/unnamed-chunk-2-2.png)

``` r
plot_rank_mobility(mobility)
```

![Map of ACS tract endpoint rank
mobility.](tidycensus-workflows_files/figure-html/unnamed-chunk-2-3.png)

## Reading the output

The first plot is the classic transition matrix: the probability that a
tract in one income class is in each class five years later, pooled over
both steps. The second splits the same transitions by the income class
of each tract’s neighbors at the start of the step. The map shows each
tract’s change in income rank between the first and last samples.

## Before using this for analysis

Two simplifications keep the example short.

- **Incomes are not comparable across samples.** Each sample reports
  income in dollars of its own final year. With pooled breaks, inflation
  and citywide growth move most tracts into higher classes, so the
  matrix mixes shared growth with relative movement. To study relative
  movement, divide each sample’s incomes by their median before
  classifying. [Get
  Started](https://dshkol.github.io/griddy/articles/griddy.md) does the
  same with state incomes and the national mean.
- **Tract boundaries changed in 2020.** The 2008–2012 and 2013–2017
  samples use 2010 tracts, and the 2018–2022 sample uses 2020 tracts.
  Matching on `GEOID` keeps tracts whose identifier persisted, but a
  persisting identifier does not guarantee an unchanged boundary, and
  split or merged tracts drop out. Interpolate the earlier samples to
  2020 tracts first, for example with
  [`tidycensus::interpolate_pw()`](https://walker-data.com/tidycensus/reference/interpolate_pw.html).
