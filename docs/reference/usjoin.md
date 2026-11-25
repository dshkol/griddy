# US State Per-Capita Personal Income, 1929-2009

Per-capita personal income for the 48 contiguous US states in nominal
dollars. Mirrors the canonical `usjoin` panel used in PySAL `giddy` and
the spatial Markov literature, so examples and validation in this
package are directly comparable to that reference work.

## Usage

``` r
usjoin
```

## Format

A tibble with 3,888 rows (48 states x 81 years) and 4 columns:

- name:

  State name.

- state_fips:

  State FIPS code, integer.

- year:

  Year, integer 1929 to 2009.

- income:

  Nominal per-capita personal income, integer USD.

## Source

PySAL `libpysal` `examples/us_income/usjoin.csv`. The original series is
constructed from US Bureau of Economic Analysis state personal income
tables. See <https://github.com/pysal/libpysal>.

## References

Rey, S. J. (2001). Spatial empirics for economic growth and convergence.
*Geographical Analysis*, 33(3), 195-214.

Rey, S. J., Kang, W., & Wolf, L. (2016). The properties of tests for
spatial effects in discrete Markov chain models of regional income
distribution dynamics. *Journal of Geographical Systems*, 18(4),
377-398.

## Examples

``` r
data(usjoin)
head(usjoin)
#> # A tibble: 6 × 4
#>   name    state_fips  year income
#>   <chr>        <int> <int>  <int>
#> 1 Alabama          1  1929    323
#> 2 Alabama          1  1930    267
#> 3 Alabama          1  1931    224
#> 4 Alabama          1  1932    162
#> 5 Alabama          1  1933    166
#> 6 Alabama          1  1934    211
range(usjoin$year)
#> [1] 1929 2009
```
