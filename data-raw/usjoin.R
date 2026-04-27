# Build the bundled `usjoin` dataset.
#
# Source: pysal/libpysal `examples/us_income/usjoin.csv` (commit at fetch time).
# The CSV ships per-capita personal income for the 48 contiguous US states from
# 1929 to 2009. PySAL's `giddy` package and the spatial Markov literature (Rey
# 2001, Rey & Kang 2016) use this panel for canonical examples.
#
# Run from the package root:
#   Rscript data-raw/usjoin.R

stopifnot(requireNamespace("readr", quietly = TRUE))
stopifnot(requireNamespace("tidyr", quietly = TRUE))
stopifnot(requireNamespace("dplyr", quietly = TRUE))
stopifnot(requireNamespace("tibble", quietly = TRUE))

raw <- readr::read_csv(
  "data-raw/usjoin.csv",
  show_col_types = FALSE
)

usjoin <- raw |>
  dplyr::rename(name = "Name", state_fips = "STATE_FIPS") |>
  tidyr::pivot_longer(
    cols = -c("name", "state_fips"),
    names_to = "year",
    values_to = "income"
  ) |>
  dplyr::mutate(
    year = as.integer(.data$year),
    state_fips = as.integer(.data$state_fips),
    income = as.integer(.data$income)
  ) |>
  dplyr::arrange(.data$name, .data$year) |>
  tibble::as_tibble()

usethis::use_data(usjoin, overwrite = TRUE, compress = "xz")
