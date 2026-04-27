# Optional R-side prior-art oracle checks.
# Install estdaR and spdyn manually before running. This script is excluded from
# the package build and should be used to create development notes or fixtures.

if (!requireNamespace("estdaR", quietly = TRUE)) {
  stop("Install estdaR before running this oracle script.", call. = FALSE)
}
if (!requireNamespace("spdyn", quietly = TRUE)) {
  stop("Install spdyn before running this oracle script.", call. = FALSE)
}

library(dplyr)
library(sf)
library(spData)
library(spdep)
library(tidyr)
library(griddy)

data(us_states, package = "spData")
data(us_states_df, package = "spData")

states <- us_states |>
  left_join(us_states_df, by = c("NAME" = "state")) |>
  filter(!NAME %in% c("Alaska", "Hawaii", "Puerto Rico")) |>
  arrange(NAME)

wide <- states |>
  st_drop_geometry() |>
  select(NAME, median_income_10, median_income_15)

panel <- states |>
  select(NAME, median_income_10, median_income_15, geometry) |>
  pivot_longer(starts_with("median_income_"), names_to = "year", values_to = "income") |>
  mutate(year = if_else(year == "median_income_10", 2010L, 2015L))

nb <- poly2nb(states, queen = TRUE)
listw <- nb2listw(nb, style = "W")

grd_classes <- classify_dynamics(panel, NAME, year, income, k = 5)
grd_classic <- markov_dynamics(grd_classes, NAME, year, class)
grd_spatial <- spatial_markov(panel, NAME, year, income, listw = listw, k = 5)

estdar_classic <- estdaR::mkv(as.matrix(wide[, c("median_income_10", "median_income_15")]), classes = 5, fixed = TRUE)
estdar_spatial <- estdaR::sp.mkv(as.matrix(wide[, c("median_income_10", "median_income_15")]), listw, classes = 5, fixed = TRUE)

spdyn_classic <- spdyn::markov(wide, stateVars = c("median_income_10", "median_income_15"), n.states = 5, pool = TRUE, std = FALSE)
spdyn_spatial <- spdyn::spMarkov(wide, listw, stateVars = c("median_income_10", "median_income_15"), n.states = 5, pool = TRUE, std = FALSE)

grd_counts <- aperm(array(
  grd_spatial$matrix$n,
  dim = c(5, 5, 5),
  dimnames = list(grd_spatial$states, grd_spatial$states, grd_spatial$lag_states)
), c(2, 1, 3))

print(transition_matrix(grd_classic, "count"))
print(estdar_classic)
print(spdyn_classic)
print(grd_spatial$matrix)
print(estdar_spatial)
print(spdyn_spatial)

dir.create("tests/testthat/fixtures", recursive = TRUE, showWarnings = FALSE)
saveRDS(
  list(
    griddy_spatial_counts = grd_counts,
    estdaR_spatial_counts = estdar_spatial$Transitions,
    spdyn_spatial_counts = spdyn_spatial$t
  ),
  "tests/testthat/fixtures/r_prior_spatial_counts.rds"
)
