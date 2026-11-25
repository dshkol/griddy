# Geospatial Distribution Dynamics With griddy

``` r
library(griddy)
library(dplyr)
library(ggplot2)
library(sf)
library(sfdep)
library(spData)
library(tidyr)
```

`griddy` works on long spatial panels: one row per place per period,
keyed by explicit `id`, `time`, and `value` columns. The bundled
`usjoin` panel contains 48 contiguous US states, per-capita personal
income, and annual observations from 1929 to 2009. It mirrors the
canonical PySAL `giddy` example used in Rey (2001).

``` r
data(usjoin)

usjoin
#> # A tibble: 3,888 × 4
#>    name    state_fips  year income
#>    <chr>        <int> <int>  <int>
#>  1 Alabama          1  1929    323
#>  2 Alabama          1  1930    267
#>  3 Alabama          1  1931    224
#>  4 Alabama          1  1932    162
#>  5 Alabama          1  1933    166
#>  6 Alabama          1  1934    211
#>  7 Alabama          1  1935    217
#>  8 Alabama          1  1936    251
#>  9 Alabama          1  1937    267
#> 10 Alabama          1  1938    244
#> # ℹ 3,878 more rows
```

## Classification

Pooled quantile classification cuts the entire panel into five bins and
reuses the same breakpoints for every year. That keeps class meanings
comparable across periods, which matters because year-specific quantiles
can hide absolute movement. A state in Q5 in 2009 is being compared to
the same income scale as a state in Q5 in 1929, not merely to its
contemporaries.

``` r
classes <- classify_dynamics(usjoin, name, year, income, k = 5)

class_intervals(classes)
#> # A tibble: 5 × 4
#>   class  lower  upper type 
#>   <ord>  <dbl>  <dbl> <chr>
#> 1 Q1      127   1049. value
#> 2 Q2     1049.  2238. value
#> 3 Q3     2238.  7050. value
#> 4 Q4     7050. 20739. value
#> 5 Q5    20739. 54528  value
```

Nominal income growth means the endpoints are nearly homogeneous under
pooled breaks: the early panel sits near the bottom of the pooled
distribution and the late panel sits near the top. A mid-panel year is a
better mapped diagnostic because it shows both the absolute class scale
and the cross-state ordering.

``` r
states <- us_states |>
  st_drop_geometry() |>
  filter(NAME %in% usjoin$name) |>
  pull(NAME)

geom <- us_states |>
  filter(NAME %in% usjoin$name) |>
  arrange(NAME)
```

``` r
class_map <- classes |>
  filter(year == 1955) |>
  left_join(geom |> select(NAME, geometry), by = c("name" = "NAME")) |>
  st_as_sf()

ggplot(class_map) +
  geom_sf(aes(fill = class), color = "white", linewidth = 0.15) +
  scale_fill_viridis_d(option = "C", direction = -1, name = "Income class") +
  coord_sf(datum = NA) +
  labs(
    title = "Pooled classes remain map-ready",
    subtitle = "1955 uses breaks estimated from the full 1929-2009 panel"
  ) +
  map_theme()
```

![Map of contiguous US states showing pooled income classes in 1955
using the same five class intervals estimated from the full 1929 to 2009
panel.](griddy_files/figure-html/unnamed-chunk-5-1.png)

## Classic Markov

The classic Markov matrix estimates movement between income classes from
one year to the next, pooling transitions across all states and adjacent
years. The [`print()`](https://rdrr.io/r/base/print.html) method gives
the transition probabilities;
[`transition_matrix()`](https://dshkol.github.io/griddy/reference/transition_matrix.md)
can return either probabilities or raw counts for downstream work.

``` r
classic <- markov_dynamics(classes, name, year, class)

classic
#> <grd_markov>
#> 5 states, 3840 observed transitions
#>     
#>               Q1          Q2          Q3          Q4          Q5
#>   Q1 0.934447301 0.065552699 0.000000000 0.000000000 0.000000000
#>   Q2 0.005148005 0.929214929 0.065637066 0.000000000 0.000000000
#>   Q3 0.000000000 0.003856041 0.934447301 0.061696658 0.000000000
#>   Q4 0.000000000 0.000000000 0.000000000 0.938223938 0.061776062
#>   Q5 0.000000000 0.000000000 0.000000000 0.000000000 1.000000000
transition_matrix(classic, "count")
#>     
#>       Q1  Q2  Q3  Q4  Q5
#>   Q1 727  51   0   0   0
#>   Q2   4 722  51   0   0
#>   Q3   0   3 727  48   0
#>   Q4   0   0   0 729  48
#>   Q5   0   0   0   0 730
steady_state(classic)
#> Q1 Q2 Q3 Q4 Q5 
#>  0  0  0  0  1

plot_transition_matrix(classic)
```

![Heatmap of classic Markov transition probabilities for US state
per-capita income, 1929 to
2009.](griddy_files/figure-html/unnamed-chunk-6-1.png)

The diagonal dominance of the matrix — most states stay in their
starting quintile from one year to the next — is the headline finding
from this panel and recovers the result Rey (2001) reports. The
stationary distribution is a mechanical summary of this empirical
matrix, not a forecast. Here Q5 is absorbing in the observed one-year
transitions, so the long-run vector puts all mass in Q5.

## Spatial Markov

Spatial Markov conditions transition probabilities on the starting class
of each unit’s spatial lag. The expectation is that being surrounded by
rich (or poor) neighbors shifts the transition odds beyond what the
unit’s own class would predict.

``` r
geom <- us_states |>
  filter(NAME %in% usjoin$name) |>
  arrange(NAME) |>
  mutate(
    nb = st_contiguity(geometry),
    wt = st_weights(nb)
  )

panel <- usjoin |>
  filter(name %in% states) |>
  arrange(name, year)
```

`geometry` is the preferred way to pass spatial weights: an `sf` tibble
with one row per unit and `nb` / `wt` list-columns produced by `sfdep`.
Carrying weights as columns on the geography keeps the spatial frame,
the weights, and their row-standardization choice in one tidy object.

``` r
spatial <- spatial_markov(panel, name, year, income, geometry = geom, k = 5)

lag_intervals(spatial)
#> # A tibble: 5 × 4
#>   class  lower  upper type       
#>   <ord>  <dbl>  <dbl> <chr>      
#> 1 Q1      181   1077. spatial_lag
#> 2 Q2     1077.  2213. spatial_lag
#> 3 Q3     2213.  7052. spatial_lag
#> 4 Q4     7052. 21042. spatial_lag
#> 5 Q5    21042. 52568. spatial_lag
transition_matrix(spatial, "probability", lag_class = "Q1")
#>            Q1        Q2 Q3 Q4 Q5
#> Q1 0.95270270 0.0472973  0  0  0
#> Q2 0.05263158 0.9473684  0  0  0
#> Q3         NA        NA NA NA NA
#> Q4         NA        NA NA NA NA
#> Q5         NA        NA NA NA NA

plot_spatial_markov(spatial)
```

![Faceted heatmaps of spatial Markov transition probabilities for US
state per-capita income, by spatial-lag
quintile.](griddy_files/figure-html/unnamed-chunk-8-1.png)

Reading the facets left to right: states whose neighbors sit in the
lowest income lag class (Q1) are much stickier at the bottom of the
distribution than the pooled transition matrix would suggest. The
spatial context conditioning is what spatial Markov is built to surface.
Grey rows indicate lag-class/state combinations with no observed
transitions, so their probabilities are undefined rather than zero.

The lag classes themselves are map-ready. The map below uses 1994
because the spatial-lag distribution is split across two classes in that
year; at the start of the panel, all states have Q1 spatial lags under
pooled nominal-income breaks. Each state’s class below is based on the
weighted income of its neighbors, not on its own income.

``` r
lag_map <- spatial$transitions |>
  filter(from_time == 1994) |>
  distinct(id, lag_class, spatial_lag) |>
  left_join(geom |> select(NAME, geometry), by = c("id" = "NAME")) |>
  st_as_sf()

ggplot(lag_map) +
  geom_sf(aes(fill = lag_class), color = "white", linewidth = 0.15) +
  scale_fill_viridis_d(option = "C", direction = -1, name = "Spatial-lag class") +
  coord_sf(datum = NA) +
  labs(
    title = "Spatial Markov conditions on neighboring-state income",
    subtitle = "Spatial-lag class in 1994"
  ) +
  map_theme()
```

![Map of contiguous US states showing each state's 1994 spatial-lag
income class based on neighboring
states.](griddy_files/figure-html/unnamed-chunk-9-1.png)

## Chain Summaries

The chain summaries need a chain in which every class can be reached
from every other. The nominal-income chain above is not one: incomes
rise across the whole panel, states drift into Q5 and stay there, and
[`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md)
stops with an error. Dividing each state’s income by the national mean
for that year removes the shared growth. This relative income is the
series that Rey (2001) and PySAL `giddy` use.

``` r
relative <- panel |>
  group_by(year) |>
  mutate(rel_income = income / mean(income)) |>
  ungroup()

rel_classes <- classify_dynamics(relative, name, year, rel_income, k = 5)
rel_chain <- markov_dynamics(rel_classes, name, year, class)
rel_chain
#> <grd_markov>
#> 5 states, 3840 observed transitions
#>     
#>               Q1          Q2          Q3          Q4          Q5
#>   Q1 0.914618370 0.075032342 0.009055627 0.001293661 0.000000000
#>   Q2 0.065703022 0.826544021 0.105124836 0.001314060 0.001314060
#>   Q3 0.005208333 0.102864583 0.794270833 0.095052083 0.002604167
#>   Q4 0.000000000 0.009138381 0.093994778 0.848563969 0.048302872
#>   Q5 0.000000000 0.000000000 0.000000000 0.062176166 0.937823834
```

[`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md)
gives the long-run share of states in each class.
[`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md)
gives the expected number of consecutive years a state stays in a class
once it enters it.
[`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md)
gives the expected number of years to reach one class from another; its
diagonal is the expected time to return to the same class.

``` r
steady_state(rel_chain)
#>        Q1        Q2        Q3        Q4        Q5 
#> 0.1795738 0.2163144 0.2149994 0.2113466 0.1777658
sojourn_time(rel_chain)
#>        Q1        Q2        Q3        Q4        Q5 
#> 11.712121  5.765152  4.860759  6.603448 16.083333
round(first_passage(rel_chain), 1)
#>       Q1   Q2   Q3   Q4    Q5
#> Q1   5.6 14.9 26.1 51.5 121.7
#> Q2  50.7  4.6 16.1 42.0 112.0
#> Q3  71.8 24.0  4.7 27.4  98.3
#> Q4  87.2 39.1 18.7  4.7  74.4
#> Q5 103.2 55.2 34.7 16.1   5.6
```

Relative incomes are persistent at both ends of the distribution. A
state that enters the bottom class stays there for about 12 years on
average, and one that enters the top class for about 16, against 5 to 7
years in the middle classes. Reaching the top class from the bottom
takes about 122 years on average, longer than the 81-year panel.

[`mobility_index()`](https://dshkol.github.io/griddy/reference/mobility_index.md)
reduces the matrix to a single number. The default, Prais–Shorrocks, is
0 when no state ever changes class and grows as more probability sits
off the diagonal. The other measures follow Formby, Smith, and Zheng
(2004) and match `giddy.mobility.markov_mobility()`.

``` r
mobility_index(rel_chain)
#>        prais  determinant        eigen bartholomew1 bartholomew2 
#>   0.16954474   0.54106184   0.04173880   0.16954474   0.03553575
```

## Testing Homogeneity

The spatial Markov matrices differ visibly by lag class.
[`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md)
asks whether the differences are larger than sampling variation would
produce. Its null hypothesis is that every lag class shares the pooled
transition matrix.

``` r
rel_spatial <- spatial_markov(
  relative, name, year, rel_income,
  geometry = geom, k = 5
)
homogeneity_test(rel_spatial)
#> # A tibble: 3 × 4
#>   test             statistic    df  p_value
#>   <chr>                <dbl> <int>    <dbl>
#> 1 chi2                  201.    60 4.72e-17
#> 2 likelihood_ratio      171.    60 1.49e-12
#> 3 kullback              171.    60 1.49e-12
```

All three tests reject homogeneity. Where a state’s neighbors sit in the
income distribution changes its own transition probabilities. The `chi2`
and `likelihood_ratio` rows match `giddy`’s `Spatial_Markov` output for
this panel. Degrees of freedom follow Bickenbach and Bode (2003), which
drop transitions that are never observed. The `kullback` row equals the
`likelihood_ratio` row by construction;
[`?homogeneity_test`](https://dshkol.github.io/griddy/reference/homogeneity_test.md)
explains why. To test regimes other than spatial-lag classes, pass a
list of count matrices; [Coverage of PySAL
giddy](https://dshkol.github.io/griddy/articles/giddy-coverage.html)
works through LISA quadrants as an example.

## Rank Mobility

[`rank_mobility()`](https://dshkol.github.io/griddy/reference/rank_mobility.md)
compares each state’s income rank between two periods. By default it
compares the first and last observed periods. Positive values mean a
state moved up the income ranking; negative values mean it moved down.
Rank-based Markov chains and the Kendall’s tau family are not `griddy`
functions; the coverage article gives recipes for the chains and lists
what is planned.

``` r
mobility_panel <- usjoin |>
  filter(name %in% states) |>
  left_join(geom |> select(NAME), by = c("name" = "NAME")) |>
  st_as_sf()

mobility <- rank_mobility(mobility_panel, name, year, income)

mobility |>
  st_drop_geometry() |>
  arrange(desc(abs_rank_change)) |>
  select(name, start_rank, end_rank, rank_change) |>
  head()
#> <grd_rank_mobility>
#> # A tibble: 6 × 4
#>   name         start_rank end_rank rank_change
#>   <chr>             <int>    <int>       <int>
#> 1 Virginia             36        6          30
#> 2 North Dakota         41       17          24
#> 3 Michigan             10       32         -22
#> 4 Ohio                 12       31         -19
#> 5 Utah                 29       47         -18
#> 6 Arizona              24       41         -17

plot_rank_mobility(mobility) +
  coord_sf(datum = NA) +
  labs(
    title = "Endpoint rank mobility, 1929 to 2009",
    subtitle = "Positive values indicate upward movement in the state income ranking"
  ) +
  map_theme()
```

![Map of endpoint rank mobility for US states, 1929 to 2009, with
positive values indicating upward rank
movement.](griddy_files/figure-html/unnamed-chunk-14-1.png)

For shorter-run churn, use adjacent-period comparisons. The same result
schema is returned, but each row describes movement from one observed
period to the next.

``` r
adjacent_mobility <- rank_mobility(panel, name, year, income, compare = "adjacent")

adjacent_mobility |>
  arrange(desc(abs_rank_change)) |>
  select(name, year, to_time, rank_change) |>
  head()
#> <grd_rank_mobility>
#> # A tibble: 6 × 4
#>   name          year to_time rank_change
#>   <chr>        <int>   <int>       <int>
#> 1 North Dakota  1972    1973          27
#> 2 North Dakota  1946    1947          23
#> 3 South Dakota  1948    1949         -22
#> 4 North Dakota  1961    1962          20
#> 5 Iowa          1947    1948          19
#> 6 North Dakota  1975    1976         -18
```

## Output schemas

Each result object exposes a tidy `transitions` table and a long
`matrix` table keyed by class labels. Inspecting them directly is the
simplest way to learn the schema.

``` r
classic$transitions |> head()
#> # A tibble: 6 × 6
#>   id      from_time to_time from_state to_state transition
#>   <chr>       <int>   <int> <ord>      <ord>    <chr>     
#> 1 Alabama      1929    1930 Q1         Q1       Q1 -> Q1  
#> 2 Alabama      1930    1931 Q1         Q1       Q1 -> Q1  
#> 3 Alabama      1931    1932 Q1         Q1       Q1 -> Q1  
#> 4 Alabama      1932    1933 Q1         Q1       Q1 -> Q1  
#> 5 Alabama      1933    1934 Q1         Q1       Q1 -> Q1  
#> 6 Alabama      1934    1935 Q1         Q1       Q1 -> Q1
spatial$transitions |> select(id, from_time, to_time, lag_class, transition, spatial_lag) |> head()
#> # A tibble: 6 × 6
#>   id      from_time to_time lag_class transition spatial_lag
#>   <chr>       <int>   <int> <ord>     <chr>            <dbl>
#> 1 Alabama      1929    1930 Q1        Q1 -> Q1          382.
#> 2 Alabama      1930    1931 Q1        Q1 -> Q1          326 
#> 3 Alabama      1931    1932 Q1        Q1 -> Q1          276.
#> 4 Alabama      1932    1933 Q1        Q1 -> Q1          211 
#> 5 Alabama      1933    1934 Q1        Q1 -> Q1          207.
#> 6 Alabama      1934    1935 Q1        Q1 -> Q1          253.
```

For programmatic access, every griddy object also has
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) and the
S3 generics
[`transition_matrix()`](https://dshkol.github.io/griddy/reference/transition_matrix.md),
[`class_intervals()`](https://dshkol.github.io/griddy/reference/class_intervals.md),
and (for spatial objects)
[`lag_intervals()`](https://dshkol.github.io/griddy/reference/lag_intervals.md).

## References

Bickenbach, F., and Bode, E. (2003). Evaluating the Markov property in
studies of economic convergence. *International Regional Science
Review*, 26(3), 363–392. <https://doi.org/10.1177/0160017603253789>

Formby, J. P., Smith, W. J., and Zheng, B. (2004). Mobility measurement,
transition matrices and statistical inference. *Journal of
Econometrics*, 120(1), 181–205.
<https://doi.org/10.1016/S0304-4076(03)00211-2>

Rey, S. J. (2001). Spatial empirics for economic growth and convergence.
*Geographical Analysis*, 33(3), 195–214.
<https://doi.org/10.1111/j.1538-4632.2001.tb00444.x>
