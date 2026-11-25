# Comparing Against estdaR and spdyn

`estdaR` (Vallone et al.) and `spdyn` (Loaiza) are earlier R
implementations of spatial distribution dynamics methods. Both remain
useful comparators, but neither is on CRAN, which makes them harder to
install and to depend on. `griddy` implements the same core spatial
Markov workflow for long `sf` panels, and its outputs keep unit
identities, time indexes, class labels, transition labels, and
spatial-lag intervals attached.

This article shows that
[`griddy::spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
produces the same transition counts as
[`estdaR::sp.mkv()`](https://rdrr.io/pkg/estdaR/man/sp.mkv.html) and
`spdyn::spMarkov()` on a shared panel, and lists the conventions that
differ between them. The comparison against PySAL `giddy`, which
`griddy` uses as its main validation oracle, is in [Coverage of PySAL
giddy](https://dshkol.github.io/griddy/articles/giddy-coverage.md).

When both packages are installed, the article calls them directly.
Otherwise it reads a fixture generated from non-CRAN installs by this
script, so the site build does not depend on either package:

``` r
install.packages("remotes")
remotes::install_github("amvallone/estdaR")
install.packages("spdyn", repos = "https://download.r-forge.r-project.org")

source("tools/oracle/r_prior_art_oracles.R")
```

``` r
library(griddy)
library(dplyr)
library(sf)
library(sfdep)
library(spData)
library(spdep)
library(tidyr)
```

## Shared panel

The comparison uses the `spData` US states income panel because it is
available from CRAN and can be represented in the wide shape expected by
both prior R implementations. `estdaR` and `spdyn` consume `listw`
objects from `spdep`; `griddy` accepts the same object for
compatibility, so all three methods use identical row-standardized
weights.

``` r
data(us_states, package = "spData")
data(us_states_df, package = "spData")

states <- us_states |>
  left_join(us_states_df, by = c("NAME" = "state")) |>
  filter(!NAME %in% c("Alaska", "Hawaii", "Puerto Rico")) |>
  arrange(NAME)

panel <- states |>
  select(NAME, median_income_10, median_income_15, geometry) |>
  pivot_longer(
    starts_with("median_income_"),
    names_to = "year",
    values_to = "income"
  ) |>
  mutate(year = if_else(year == "median_income_10", 2010L, 2015L))

nb <- poly2nb(states, queen = TRUE)
listw <- nb2listw(nb, style = "W")

spatial <- spatial_markov(panel, NAME, year, income, listw = listw, k = 5)

lag_intervals(spatial)
```

    ## # A tibble: 5 × 4
    ##   class  lower  upper type       
    ##   <ord>  <dbl>  <dbl> <chr>      
    ## 1 Q1    21806. 24582. spatial_lag
    ## 2 Q2    24582. 25701. spatial_lag
    ## 3 Q3    25701. 26850. spatial_lag
    ## 4 Q4    26850. 28552. spatial_lag
    ## 5 Q5    28552. 33541  spatial_lag

``` r
transition_matrix(spatial, "count", lag_class = "Q1")
```

    ##    Q1 Q2 Q3 Q4 Q5
    ## Q1  4  2  0  0  0
    ## Q2  0  1  3  0  0
    ## Q3  0  0  1  0  0
    ## Q4  0  0  0  0  1
    ## Q5  0  0  0  0  0

## Cross-package agreement

The next chunk compares `griddy`’s counts with both packages, live or
from the fixture as described above.

``` r
has_live_oracles <- requireNamespace("estdaR", quietly = TRUE) &&
  requireNamespace("spdyn", quietly = TRUE)

wide <- panel |>
  st_drop_geometry() |>
  pivot_wider(id_cols = NAME, names_from = year, values_from = income) |>
  arrange(NAME)

wide_mat <- as.matrix(wide |> select(-NAME))
year_cols <- as.character(unique(panel$year))

griddy_counts <- aperm(
  array(
    spatial$matrix$n,
    dim = c(5, 5, 5),
    dimnames = list(spatial$states, spatial$states, spatial$lag_states)
  ),
  c(2, 1, 3)
)

if (has_live_oracles) {
  estdar_sp <- estdaR::sp.mkv(wide_mat, listw, classes = 5, fixed = TRUE)
  spdyn_sp <- spdyn::spMarkov(
    wide,
    listw,
    stateVars = year_cols,
    n.states = 5,
    pool = TRUE,
    std = FALSE
  )

  estdaR_counts <- estdar_sp$Transitions
  spdyn_counts <- spdyn_sp$t
} else {
  fixture_path <- file.path("..", "..", "tests", "testthat", "fixtures", "r_prior_spatial_counts.rds")
  fixture <- readRDS(fixture_path)
  estdaR_counts <- fixture$estdaR_spatial_counts
  spdyn_counts <- fixture$spdyn_spatial_counts
}

all.equal(unname(griddy_counts), unname(estdaR_counts))
```

    ## [1] TRUE

``` r
all.equal(unname(griddy_counts), unname(spdyn_counts))
```

    ## [1] TRUE

When the two prior implementations and `griddy` agree to within
numerical tolerance, both calls return `TRUE`. Disagreements with both
at once are treated as bugs in `griddy`. Disagreements with one but not
the other are documented under “Conventions worth knowing” below.

## Conventions worth knowing

Three places where a naive cross-comparison can produce false
disagreement:

- **Classification breaks.** `griddy` uses pooled quantiles by default;
  `estdaR` accepts `fixed = TRUE`/`FALSE` to choose; `spdyn` exposes
  `pool`. Match those before comparing matrices.
- **Standardization.** `spdyn::spMarkov(..., std = TRUE)` standardizes
  the panel by year mean before classifying. `griddy` does not
  standardize by default. Set `std = FALSE` for direct comparison.
- **Output shape.** `estdaR` returns a 3D array indexed
  `[from, to, lag]`. `spdyn` returns an object with a `$t` field of the
  same shape. `griddy` returns a long `matrix` tibble keyed by
  `(lag_class, from_state, to_state)`, which is what makes downstream
  `dplyr` work natural.

The package test suite uses static fixtures from
[`estdaR::sp.mkv()`](https://rdrr.io/pkg/estdaR/man/sp.mkv.html) and
`spdyn::spMarkov()` so ordinary CI can validate the spatial Markov
counts without installing either package. The live oracle script in
`tools/oracle/` can be run manually after installing both prior-art
packages to refresh the fixture.
