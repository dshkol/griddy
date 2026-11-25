# Coverage of PySAL giddy

The methods in `griddy` come from the spatial distribution dynamics
literature, most directly the spatial Markov chain of Rey (2001) and the
homogeneity tests studied by Rey, Kang, and Wolf (2016). Their reference
implementation is PySAL [`giddy`](https://pysal.org/giddy/). `griddy`
implements the same methods in R, for long `sf` panels with tidy
outputs.

`griddy` is not a port of `giddy`. It uses `giddy` as a validation
oracle rather than as a specification. Static fixtures from giddy 2.3.9
check the classic and spatial Markov counts and probabilities, sojourn
and first-passage times, the mobility indices, and the Pearson and
likelihood-ratio homogeneity statistics. Some `giddy` features take only
a few lines of `griddy`, `sfdep`, `dplyr`, or base R, and are documented
here as recipes rather than added as functions.

This article maps every public entry of giddy 2.3.9 onto `griddy`.

## How to read the table

Each entry falls into one of four categories:

- **Implemented**: a `griddy` function covers it.
- **Composition**: there is no dedicated function, but a short recipe
  built from `griddy`, `sfdep`, `dplyr`, or base R produces the same
  result. The longer recipes are worked through
  [below](#worked-compositions), with checks against giddy 2.3.9 output.
- **Planned**: deliberately deferred to a later release.
- **Out of scope**: `griddy` does not intend to cover it. The table
  points to the tool that does.

The enumeration covers the `__all__` lists of the `markov`, `ergodic`,
`mobility`, `rank`, `directional`, `sequence`, and `util` modules. Where
a class has attributes or options with a different answer from the class
as a whole, they get their own row. The `giddy.plotting` functions
belong to `Rose` and are grouped with it. `giddy.components` is an
internal helper for `LISA_Markov.spillover()`.

## Coverage table

| giddy 2.3.9 | Category | In griddy, or where to go |
|:---|:---|:---|
| `markov.Markov`: `transitions`, `p` | Implemented | [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md), [`transition_matrix()`](https://dshkol.github.io/griddy/reference/transition_matrix.md), with classes from [`classify_dynamics()`](https://dshkol.github.io/griddy/reference/classify_dynamics.md) |
| `markov.Markov`: `steady_state`, `mfpt`, `sojourn_time` | Implemented | [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md), [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md), [`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md) |
| `markov.Markov`: communicating, recurrent, and absorbing classes; multiple steady states of a reducible chain | Out of scope | The [`markovchain`](https://CRAN.R-project.org/package=markovchain) package: `communicatingClasses()`, `recurrentClasses()`, `absorbingStates()`, `steadyStates()`. `griddy`’s chain summaries assume one recurrent class, and [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md) requires an irreducible chain. |
| `markov.Markov(fill_empty_classes = True)` | Composition | `griddy` leaves rows with no departures as `NA`. To fill them: `P[is.na(P)] <- 0; diag(P)[rowSums(P) == 0] <- 1` ([recipe](#smaller-recipes)) |
| `markov.Spatial_Markov`: `T`, `P`, `transitions`, `p`; pooled classes (`fixed = True`); `k`, `m` | Implemented | [`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md) with `k` and `lag_k`, `transition_matrix(x, lag_class = ...)`, [`class_intervals()`](https://dshkol.github.io/griddy/reference/class_intervals.md), [`lag_intervals()`](https://dshkol.github.io/griddy/reference/lag_intervals.md) |
| `markov.Spatial_Markov`: `s`, `f`, `S`, `F` | Composition | [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md) and [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md) applied to `transition_matrix(x, lag_class = ...)` for each lag class; the aspatial `s` and `f` come from a [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md) chain ([recipe](#conditional-chain-summaries)) |
| `markov.Spatial_Markov`: `Q`, `LR`, `dof_hom`, `ht`, [`summary()`](https://rdrr.io/r/base/summary.html) | Implemented | [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md), `chi2` and `likelihood_ratio` rows |
| `markov.Spatial_Markov`: `x2`, `x2_pvalue`, `x2_dof` | Implemented | `x2` is the same Pearson statistic as `Q`, the `chi2` row of [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md). giddy tests `x2` against k(k − 1)² degrees of freedom; [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md) uses the Bickenbach and Bode count, as giddy does for `Q`. |
| `markov.Spatial_Markov`: `chi2` (one test per lag class); `markov.chi2()` | Composition | A short function on `transition_matrix(x, "count", lag_class = ...)` and the pooled counts ([recipe](#smaller-recipes)) |
| `markov.Spatial_Markov(fixed = False)`, `cutoffs`, `lag_cutoffs`, `discrete = True` | Composition | Value classes: `classify_dynamics(method = "time_quantile")` or `method = "fixed"` with `breaks`. Lag classes: join any per-unit, per-period regime to the `transitions` of a [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md) chain and count by it. Examples: a spatial lag cut at your own breaks or within each period, or the most common neighbouring class from [`sfdep::find_xj()`](https://rdrr.io/pkg/sfdep/man/find_xj.html) ([recipe](#conditioning-on-any-regime)). |
| `markov.Spatial_Markov`: `shtest`; permutation inference (`permutations`, `x2_rpvalue`, `x2_realizations`) | Out of scope | Use [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md). giddy’s documentation advises caution with `shtest` and `chi2` and describes the permutation `x2` test as experimental. |
| `markov.LISA_Markov`: `q`, `transitions`, `p`, `steady_state`, `move_types`, `geoda_quads` | Composition | Quadrants from [`sfdep::local_moran()`](https://rdrr.io/pkg/sfdep/man/local_moran.html) for each period, passed to [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md). Move types are the `transition` column; GeoDa numbering is a relabelling of the factor levels ([recipe](#lisa-markov)). |
| `markov.LISA_Markov(permutations > 0)`: `p_values`, `significant_moves` | Composition | Join the permutation p-values from [`sfdep::local_moran()`](https://rdrr.io/pkg/sfdep/man/local_moran.html) at the origin and destination periods to the chain’s `transitions` |
| `markov.LISA_Markov`: `chi_2`, `expected_t` | Out of scope | `griddy` has no test that own and neighbour moves are independent. To test whether transitions differ by LISA quadrant, condition on the quadrant and use [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md) ([recipe](#lisa-markov)). |
| `markov.LISA_Markov.spillover()` | Out of scope | [`spdep::subset.nb()`](https://r-spatial.github.io/spdep/reference/subset.nb.html) and [`spdep::n.comp.nb()`](https://r-spatial.github.io/spdep/reference/compon.html) find connected clusters among units with significant [`sfdep::local_moran()`](https://rdrr.io/pkg/sfdep/man/local_moran.html) results, which is what it builds on |
| `markov.kullback()` | Implemented | [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md), `kullback` row, which [differs on purpose](#giddy-differences) |
| `markov.homogeneity()`, `markov.Homogeneity_Results` | Implemented | [`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md) on a list of regime count matrices |
| `markov.prais()` | Composition | `1 - diag(transition_matrix(x))`; the scalar Prais–Shorrocks index is `mobility_index(x, "prais")` |
| `markov.sojourn_time()` | Implemented | [`sojourn_time()`](https://dshkol.github.io/griddy/reference/sojourn_time.md) |
| `markov.FullRank_Markov` | Planned | Until then, `classify_dynamics(method = "time_quantile", k = n)` followed by [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md) gives the same transition counts ([recipe](#rank-markov-chains)) |
| `markov.GeoRank_Markov` | Planned | Until then, [`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md) with the within-period rank as `id` and the unit as `state` gives the same transition counts ([recipe](#rank-markov-chains)) |
| `ergodic.steady_state()` | Implemented | [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md) |
| `ergodic.mfpt()`, deprecated `ergodic.fmpt()` | Implemented | [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md), for irreducible chains |
| `ergodic.var_mfpt_ergodic()`, deprecated `ergodic.var_fmpt_ergodic()` | Composition | Kemeny and Snell’s variance formula, using [`first_passage()`](https://dshkol.github.io/griddy/reference/first_passage.md), [`steady_state()`](https://dshkol.github.io/griddy/reference/steady_state.md), and the fundamental matrix ([recipe](#smaller-recipes)) |
| `mobility.markov_mobility()` | Implemented | [`mobility_index()`](https://dshkol.github.io/griddy/reference/mobility_index.md): `"P"`, `"D"`, `"L2"`, `"B1"`, `"B2"` are `"prais"`, `"determinant"`, `"eigen"`, `"bartholomew1"`, `"bartholomew2"` |
| `rank.Tau` | Composition | `stats::cor.test(x, y, method = "kendall")` returns the same tau-b. The asymptotic p-values differ slightly. |
| `rank.SpatialTau`, `rank.Tau_Local`, `rank.Tau_Local_Neighbor`, `rank.Tau_Local_Neighborhood`, `rank.Tau_Regional` | Planned | Spatial and local decompositions of Kendall’s tau, including the local indicators of mobility association (LIMA) |
| `rank.Theta` | Composition | Rank each period with [`rank()`](https://rdrr.io/r/base/rank.html), take each unit’s rank change between adjacent periods, then compute `sum(abs(tapply(change, regime, sum))) / sum(abs(change))` for each pair of adjacent periods. Use `sample(regime)` for permutation inference. [`rank_mobility()`](https://dshkol.github.io/griddy/reference/rank_mobility.md) gives tied values the minimum rank rather than the average, so it reproduces `Theta` only when there are no ties. |
| `directional.Rose`, its `permute()` and plot methods, and the `giddy.plotting` functions | Planned | Rose diagrams of directional LISA vectors |
| `sequence.Sequence` | Out of scope | [`TraMineR`](https://CRAN.R-project.org/package=TraMineR): `seqdef()` and `seqdist()` with `method = "HAM"`, `"OM"`, or `"OMstran"`; transition-rate substitution costs come from `seqcost(method = "TRATE")` |
| `util.fill_empty_diagonals()` | Composition | As for `fill_empty_classes` above |
| `util.shuffle_matrix()` | Composition | `i <- sample(nrow(X)); X[i, i]` |
| `util.get_lower()` | Composition | `t(X)[upper.tri(X)]` returns the lower triangle in giddy’s row-major order |

## Worked compositions

The examples use the bundled `usjoin` panel of state per-capita income.
The geometry comes from
[`spData::us_states`](https://jakubnowosad.com/spData/reference/us_states.html),
and its queen contiguity matches the `states48.gal` weights in giddy’s
examples, so results can be compared with giddy directly.

``` r
library(griddy)
library(dplyr)
library(sf)
library(sfdep)

data(usjoin)
data(us_states, package = "spData")

states <- us_states |>
  filter(NAME %in% usjoin$name) |>
  arrange(NAME) |>
  select(name = NAME) |>
  mutate(
    nb = st_contiguity(geometry),
    wt = st_weights(nb)
  )

panel <- usjoin |>
  group_by(year) |>
  mutate(rel_income = income / mean(income)) |>
  ungroup() |>
  arrange(year, name)
```

### LISA Markov

[`sfdep::local_moran()`](https://rdrr.io/pkg/sfdep/man/local_moran.html)
returns each unit’s quadrant. Its `pysal` column uses the same
convention as giddy: the standardized value against its spatial lag.
Computing quadrants for each period and passing them to
[`markov_dynamics()`](https://dshkol.github.io/griddy/reference/markov_dynamics.md)
gives the LISA Markov chain.

``` r
set.seed(2001)
lisa_panel <- panel |>
  group_by(year) |>
  mutate(quadrant = local_moran(income, states$nb, states$wt, nsim = 99)$pysal) |>
  ungroup() |>
  mutate(quadrant = factor(
    quadrant,
    levels = c("High-High", "Low-High", "Low-Low", "High-Low")
  ))

lisa <- markov_dynamics(lisa_panel, name, year, quadrant)
transition_matrix(lisa, "count")
```

    ##            
    ##             High-High Low-High Low-Low High-Low
    ##   High-High      1087       44       4       34
    ##   Low-High         41      470      36        1
    ##   Low-Low           5       34    1422       39
    ##   High-Low         30        1      40      552

The counts match `giddy.markov.LISA_Markov` on the same data and
weights:

``` r
giddy_lisa_counts <- matrix(
  c(1087,   44,    4,  34,
      41,  470,   36,   1,
       5,   34, 1422,  39,
      30,    1,   40, 552),
  nrow = 4, byrow = TRUE
)
all.equal(as.vector(transition_matrix(lisa, "count")), as.vector(giddy_lisa_counts))
```

    ## [1] TRUE

The result is an ordinary `grd_markov` object, so the chain summaries
apply:

``` r
steady_state(lisa)
```

    ## High-High  Low-High   Low-Low  High-Low 
    ## 0.2856150 0.1419023 0.4049367 0.1675460

``` r
sojourn_time(lisa)
```

    ## High-High  Low-High   Low-Low  High-Low 
    ## 14.256098  7.025641 19.230769  8.774648

To ask whether income-class transitions differ by LISA quadrant,
condition on the quadrant at the start of each transition and test
homogeneity across quadrants:

``` r
income_chain <- classify_dynamics(lisa_panel, name, year, rel_income, k = 5) |>
  markov_dynamics(name, year, class)

by_quadrant <- income_chain$transitions |>
  left_join(
    lisa_panel |> select(id = name, from_time = year, quadrant),
    by = c("id", "from_time")
  )

quadrant_counts <- lapply(
  split(by_quadrant, by_quadrant$quadrant),
  function(d) table(d$from_state, d$to_state)
)
homogeneity_test(quadrant_counts)
```

    ## # A tibble: 3 × 4
    ##   test             statistic    df  p_value
    ##   <chr>                <dbl> <int>    <dbl>
    ## 1 chi2                  156.    23 9.72e-22
    ## 2 likelihood_ratio      167.    23 8.76e-24
    ## 3 kullback              167.    23 8.76e-24

### Conditioning on any regime

The quadrant example is a general pattern. Join any per-unit, per-period
regime to a chain’s `transitions`, count by regime, and pass the list of
count matrices to
[`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md).
[`spatial_markov()`](https://dshkol.github.io/griddy/reference/spatial_markov.md)
uses the same pattern with pooled quantiles of the spatial lag. Applying
the pattern to its lag classes reproduces its result:

``` r
spatial <- spatial_markov(panel, name, year, rel_income, geometry = states, k = 5)

by_lag <- income_chain$transitions |>
  left_join(
    spatial$lag_panel |> select(id = name, from_time = year, lag_class),
    by = c("id", "from_time")
  )

lag_counts <- lapply(
  split(by_lag, by_lag$lag_class),
  function(d) table(d$from_state, d$to_state)
)
all.equal(homogeneity_test(lag_counts), homogeneity_test(spatial))
```

    ## [1] TRUE

To use your own lag breaks, per-period lag quantiles, or a categorical
lag, replace `lag_class` in the join with that regime.

### Conditional chain summaries

The conditional steady states and first-passage times (giddy’s `S` and
`F`) come from applying the chain summaries to each lag class’s matrix:

``` r
conditional_steady_state <- sapply(
  spatial$lag_states,
  function(l) steady_state(transition_matrix(spatial, lag_class = l))
)
round(t(conditional_steady_state), 3)
```

    ##       Q1    Q2    Q3    Q4    Q5
    ## Q1 0.435 0.264 0.204 0.068 0.029
    ## Q2 0.134 0.340 0.252 0.233 0.041
    ## Q3 0.121 0.211 0.264 0.290 0.114
    ## Q4 0.078 0.197 0.254 0.225 0.247
    ## Q5 0.018 0.200 0.190 0.255 0.337

``` r
first_passage(transition_matrix(spatial, lag_class = "Q1"))
```

    ##           Q1        Q2        Q3       Q4        Q5
    ## Q1  2.298353 28.956140 46.142857 80.80952 279.42857
    ## Q2 33.865497  3.794596 22.571429 57.23810 255.85714
    ## Q3 43.602339  9.736842  4.910857 34.66667 233.28571
    ## Q4 46.628655 12.763158  6.257143 14.61565 198.61905
    ## Q5 52.628655 18.763158 12.257143  6.00000  34.10317

### Rank Markov chains

Full rank and geographic rank Markov chains are planned. In the
meantime, both can be built with existing functions. These reproduce the
transition counts of giddy’s `FullRank_Markov` and `GeoRank_Markov` on
`usjoin`. In `griddy`, rank state `Q1` is the lowest income; giddy
numbers ranks from the highest.

``` r
full_rank <- usjoin |>
  classify_dynamics(name, year, income, method = "time_quantile", k = 48) |>
  markov_dynamics(name, year, class)

geo_rank <- usjoin |>
  group_by(year) |>
  mutate(rank = rank(income, ties.method = "first")) |>
  ungroup() |>
  markov_dynamics(rank, year, name)

dim(transition_matrix(full_rank))
```

    ## [1] 48 48

``` r
dim(transition_matrix(geo_rank))
```

    ## [1] 48 48

### Smaller recipes

Pearson tests of each lag class’s counts against the pooled
probabilities (giddy’s `markov.chi2()` and `Spatial_Markov.chi2`). Their
sum is the `chi2` row of
[`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md):

``` r
chi2_vs <- function(counts, reference) {
  expected <- rowSums(counts) * prop.table(reference, 1)
  expected[is.na(expected)] <- 0
  sum((counts - expected)^2 / ifelse(expected == 0, 1, expected))
}

pooled <- Reduce(`+`, lag_counts)
per_lag <- vapply(lag_counts, chi2_vs, numeric(1), reference = pooled)
per_lag
```

    ##       Q1       Q2       Q3       Q4       Q5 
    ## 40.55985 55.47520 17.75290 40.03910 46.79668

``` r
giddy_per_lag <- c(
  40.5598541260764, 55.4751973848766, 17.7528996233674,
  40.0390961477108, 46.7966803487369
)
all.equal(unname(per_lag), giddy_per_lag)
```

    ## [1] TRUE

``` r
all.equal(sum(per_lag), homogeneity_test(spatial)$statistic[1])
```

    ## [1] TRUE

Variances of first-passage times (Kemeny and Snell), checked against the
example in giddy’s `var_mfpt_ergodic()` documentation:

``` r
var_first_passage <- function(P) {
  k <- nrow(P)
  stat <- steady_state(P)
  Z <- solve(diag(k) - P + matrix(stat, k, k, byrow = TRUE))
  M <- first_passage(P)
  ZM <- Z %*% M
  W <- M %*% (2 * diag(diag(Z)) %*% diag(1 / stat) - diag(k)) +
    2 * (ZM - matrix(1, k, k) %*% diag(diag(ZM)))
  W - M * M
}

P <- matrix(c(0.5, 0.25, 0.25, 0.5, 0, 0.5, 0.25, 0.25, 0.5), 3, byrow = TRUE)
var_first_passage(P)
```

    ##          [,1] [,2]     [,3]
    ## [1,] 5.583333   12 6.888889
    ## [2,] 6.222222   12 6.222222
    ## [3,] 6.888889   12 5.583333

Per-class Prais mobility (giddy’s `markov.prais()`), filling rows with
no departures, and giddy’s `util.get_lower()` ordering:

``` r
1 - diag(transition_matrix(income_chain))
```

    ##         Q1         Q2         Q3         Q4         Q5 
    ## 0.08538163 0.17345598 0.20572917 0.15143603 0.06217617

``` r
P <- matrix(c(0.5, 0.5, 0, NA, NA, NA, 0, 0.2, 0.8), 3, byrow = TRUE)
P[is.na(P)] <- 0
diag(P)[rowSums(P) == 0] <- 1
P
```

    ##      [,1] [,2] [,3]
    ## [1,]  0.5  0.5  0.0
    ## [2,]  0.0  1.0  0.0
    ## [3,]  0.0  0.2  0.8

``` r
X <- matrix(c(0, 1, 2, 3, 1, 0, 1, 2, 2, 1, 0, 1, 4, 2, 1, 0), 4, byrow = TRUE)
t(X)[upper.tri(X)]
```

    ## [1] 1 2 1 4 2 1

## Where griddy differs from giddy 2.3.9

There is one intentional difference. In
[`homogeneity_test()`](https://dshkol.github.io/griddy/reference/homogeneity_test.md),
the `chi2` and `likelihood_ratio` rows match giddy’s `Spatial_Markov.Q`
and `Spatial_Markov.LR`. The `kullback` row does not match
`giddy.markov.kullback()` in giddy 2.3.9, for two reasons:

- It uses origin-state (row) margins for the stratum-specific term.
  giddy 2.3.9 uses terminal-state margins, which
  [pysal/giddy#260](https://github.com/pysal/giddy/pull/260) fixes
  upstream.
- It uses the Bickenbach and Bode (2003) degrees of freedom instead of
  r(s − 1)(r − 1), which overstates the degrees of freedom when some
  transitions are never observed. See
  [pysal/giddy#265](https://github.com/pysal/giddy/issues/265).

With origin-state margins the Kullback statistic is algebraically the
likelihood-ratio statistic. With the same degrees of freedom, the
`kullback` row therefore equals the `likelihood_ratio` row. It is kept
for comparability with giddy. See the
[NEWS](https://dshkol.github.io/griddy/news/index.md) entry for 0.2.0
and
[`?homogeneity_test`](https://dshkol.github.io/griddy/reference/homogeneity_test.md).

## References

Bickenbach, F., and Bode, E. (2003). Evaluating the Markov property in
studies of economic convergence. *International Regional Science
Review*, 26(3), 363–392.

Kemeny, J. G., and Snell, J. L. (1976). *Finite Markov Chains*.
Springer.

Rey, S. J. (2001). Spatial empirics for economic growth and convergence.
*Geographical Analysis*, 33(3), 195–214.
<https://doi.org/10.1111/j.1538-4632.2001.tb00444.x>

Rey, S. J., Kang, W., and Wolf, L. (2016). The properties of tests for
spatial effects in discrete Markov chain models of regional income
distribution dynamics. *Journal of Geographical Systems*, 18(4),
377–398. <https://doi.org/10.1007/s10109-016-0234-x>
