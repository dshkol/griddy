# Working With cancensus

``` r
library(griddy)
library(dplyr)
```

This article runs the core `griddy` workflow on census tracts in the
City of Vancouver, using median total household income from the 2016 and
2021 censuses (incomes for 2015 and 2020). It needs a CensusMapper API
key. It renders on the pkgdown site when one is set and does not ship
with the package.

``` r
library(cancensus)
```

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.

``` r
library(sf)
```

    ## Warning: package 'sf' was built under R version 4.5.2

    ## Linking to GEOS 3.13.0, GDAL 3.8.5, PROJ 9.5.1; sf_use_s2() is TRUE

``` r
library(sfdep)

regions <- list(CSD = "5915022") # Vancouver CSD
vectors <- c(
  income_2016 = "v_CA16_2397",
  income_2021 = "v_CA21_906"
)

panel_2016 <- get_census(
  dataset = "CA16",
  regions = regions,
  vectors = vectors["income_2016"],
  level = "CT",
  geo_format = "sf"
) |>
  transmute(GeoUID, year = 2016L, median_income = income_2016, geometry)
```

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.

    ## Querying CensusMapper API...

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.

    ## Querying CensusMapper API...

``` r
panel_2021 <- get_census(
  dataset = "CA21",
  regions = regions,
  vectors = vectors["income_2021"],
  level = "CT",
  geo_format = "sf"
) |>
  transmute(GeoUID, year = 2021L, median_income = income_2021, geometry)
```

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.
    ## 
    ## 
    ## Querying CensusMapper API...

    ## Census data is currently stored temporarily.
    ## 
    ##  In order to speed up performance, reduce API quota usage, and reduce unnecessary network calls, please set up a persistent cache directory via `set_cancensus_cache_path('<local cache path>', install = TRUE)`.
    ##  This will add your cache directory as environment varianble to your .Renviron to be used across sessions and projects.

    ## Querying CensusMapper API...

``` r
common_ids <- intersect(panel_2016$GeoUID, panel_2021$GeoUID)
panel <- bind_rows(panel_2016, panel_2021) |>
  filter(GeoUID %in% common_ids)
geography <- panel |>
  filter(year == 2021L) |>
  arrange(GeoUID) |>
  mutate(
    nb = st_contiguity(geometry, queen = TRUE),
    wt = st_weights(nb, allow_zero = TRUE)
  )
```

    ## Warning: There were 2 warnings in `stopifnot()`.
    ## The first warning was:
    ## ℹ In argument: `nb = st_contiguity(geometry, queen = TRUE)`.
    ## Caused by warning in `spdep::poly2nb()`:
    ## ! some observations have no neighbours;
    ## if this seems unexpected, try increasing the snap argument.
    ## ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning.

``` r
classes <- classify_dynamics(panel, GeoUID, year, median_income, k = 5)
classic <- markov_dynamics(classes, GeoUID, year, class)
spatial <- spatial_markov(panel, GeoUID, year, median_income, geometry = geography, k = 5)

plot_transition_matrix(classic)
```

![Heatmap of Canadian Census tract transition probabilities between
income
quintiles.](cancensus-workflows_files/figure-html/unnamed-chunk-2-1.png)

``` r
plot_spatial_markov(spatial)
```

![Faceted heatmaps of Canadian Census tract spatial Markov transition
probabilities by spatial-lag
quintile.](cancensus-workflows_files/figure-html/unnamed-chunk-2-2.png)

## Reading the output

With two censuses, each tract contributes exactly one transition, from
2016 to 2021. The first plot is the transition matrix over those moves.
The second splits them by the income class of each tract’s neighbors in
2016. With one transition per tract, the conditional matrices rest on
few observations, so treat them as an illustration.

## Before using this for analysis

- **Incomes are nominal.** 2015 and 2020 incomes are not adjusted for
  inflation, so pooled classes mix shared growth with relative movement.
  Divide each census’s incomes by their median before classifying to
  study relative movement.
- **Tract boundaries change between censuses.** Matching on `GeoUID`
  keeps tracts whose identifier persisted, but a persisting identifier
  does not guarantee an unchanged boundary. The
  [`tongfen`](https://CRAN.R-project.org/package=tongfen) package builds
  a common geography across census years.
