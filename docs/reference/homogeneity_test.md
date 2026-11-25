# Test Homogeneity Of Transition Matrices Across Regimes

Tests whether transition dynamics are homogeneous across regimes – for a
spatial Markov object, whether the transition matrices conditioned on
spatial-lag class genuinely differ from the pooled matrix (Rey, Kang,
and Wolf 2016). Three statistics are reported: a Pearson chi-squared Q
test and a likelihood-ratio test with the degrees-of-freedom adjustment
of Bickenbach and Bode (2003), and the Kullback information test
(Kullback, Kupperman, and Ku 1962). The Pearson and likelihood-ratio
statistics mirror the PySAL `giddy` `Spatial_Markov` homogeneity
attributes.

## Usage

``` r
homogeneity_test(x, ...)
```

## Arguments

- x:

  A `grd_spatial_markov` object, or a list of regime transition count
  matrices of identical dimensions (counts, not probabilities).

- ...:

  Reserved for future methods.

## Value

A tibble with one row per test (`chi2`, `likelihood_ratio`, `kullback`)
and columns `test`, `statistic`, `df`, and `p_value`. The null
hypothesis is that all regimes share the pooled transition matrix; small
p-values indicate the conditional dynamics differ.

## Details

The Kullback statistic uses origin-state (row) margins, which makes it
algebraically identical to the likelihood-ratio statistic. It is
reported for comparability with `giddy.markov.kullback()` and uses the
same Bickenbach–Bode degrees of freedom as the other two tests. giddy
2.3.9 and earlier differ in two ways: the stratum-specific term uses
terminal-state (column) margins (fixed upstream in
<https://github.com/pysal/giddy/pull/260>), and the degrees of freedom
are the unadjusted \\r(s - 1)(r - 1)\\, which overstates them when some
transitions are never observed (see
<https://github.com/pysal/giddy/issues/265>). Origin states with no
transitions in any regime contribute no degrees of freedom to any of the
three tests.

## References

Bickenbach, F., and Bode, E. (2003). Evaluating the Markov property in
studies of economic convergence. *International Regional Science
Review*, 26(3), 363–392.
[doi:10.1177/0160017603253789](https://doi.org/10.1177/0160017603253789)

Kullback, S., Kupperman, M., and Ku, H. H. (1962). Tests for contingency
tables and Markov chains. *Technometrics*, 4(4), 573–608.
[doi:10.1080/00401706.1962.10490041](https://doi.org/10.1080/00401706.1962.10490041)

Rey, S. J., Kang, W., and Wolf, L. (2016). The properties of tests for
spatial effects in discrete Markov chain models of regional income
distribution dynamics. *Journal of Geographical Systems*, 18(4),
377–398.
[doi:10.1007/s10109-016-0234-x](https://doi.org/10.1007/s10109-016-0234-x)

## Examples

``` r
panel <- data.frame(
  id = rep(1:9, each = 3),
  year = rep(2020:2022, times = 9),
  value = c(
    1, 2, 3, 4, 3, 5, 6, 7, 6, 8, 9, 10, 11, 10,
    12, 13, 14, 13, 15, 16, 17, 18, 17, 19, 20, 21, 20
  )
)
grid <- sf::st_sf(
  id = 1:9,
  geometry = sf::st_make_grid(
    sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 3, ymax = 3)),
    n = c(3, 3)
  )
) |>
  dplyr::mutate(
    nb = sfdep::st_contiguity(geometry),
    wt = sfdep::st_weights(nb)
  )
spatial <- spatial_markov(panel, id, year, value, geometry = grid, k = 3)
homogeneity_test(spatial)
#> # A tibble: 3 × 4
#>   test             statistic    df p_value
#>   <chr>                <dbl> <int>   <dbl>
#> 1 chi2                     0     0       1
#> 2 likelihood_ratio         0     0       1
#> 3 kullback                 0     0       1
```
