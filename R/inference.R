#' Test Homogeneity Of Transition Matrices Across Regimes
#'
#' Tests whether transition dynamics are homogeneous across regimes -- for a
#' spatial Markov object, whether the transition matrices conditioned on
#' spatial-lag class genuinely differ from the pooled matrix (Rey, Kang, and
#' Wolf 2016). Three statistics are reported: a Pearson chi-squared Q test and
#' a likelihood-ratio test with the degrees-of-freedom adjustment of
#' Bickenbach and Bode (2003), and the Kullback information test (Kullback,
#' Kupperman, and Ku 1962). The Pearson and likelihood-ratio statistics mirror
#' the PySAL `giddy` `Spatial_Markov` homogeneity attributes.
#'
#' The Kullback statistic uses origin-state (row) margins, which makes it
#' algebraically identical to the likelihood-ratio statistic. It is reported
#' for comparability with `giddy.markov.kullback()` and uses the same
#' Bickenbach--Bode degrees of freedom as the other two tests. giddy 2.3.9 and
#' earlier differ in two ways: the stratum-specific term uses terminal-state
#' (column) margins (fixed upstream in
#' <https://github.com/pysal/giddy/pull/260>), and the degrees of freedom are
#' the unadjusted \eqn{r(s - 1)(r - 1)}, which overstates them when some
#' transitions are never observed (see
#' <https://github.com/pysal/giddy/issues/265>). Origin states with no
#' transitions in any regime contribute no degrees of freedom to any of the
#' three tests.
#'
#' @param x A `grd_spatial_markov` object, or a list of regime transition
#'   count matrices of identical dimensions (counts, not probabilities).
#' @param ... Reserved for future methods.
#'
#' @return A tibble with one row per test (`chi2`, `likelihood_ratio`,
#'   `kullback`) and columns `test`, `statistic`, `df`, and `p_value`. The
#'   null hypothesis is that all regimes share the pooled transition matrix;
#'   small p-values indicate the conditional dynamics differ.
#'
#' @references
#' Bickenbach, F., and Bode, E. (2003). Evaluating the Markov property in
#' studies of economic convergence. *International Regional Science Review*,
#' 26(3), 363--392. \doi{10.1177/0160017603253789}
#'
#' Kullback, S., Kupperman, M., and Ku, H. H. (1962). Tests for contingency
#' tables and Markov chains. *Technometrics*, 4(4), 573--608.
#' \doi{10.1080/00401706.1962.10490041}
#'
#' Rey, S. J., Kang, W., and Wolf, L. (2016). The properties of tests for
#' spatial effects in discrete Markov chain models of regional income
#' distribution dynamics. *Journal of Geographical Systems*, 18(4), 377--398.
#' \doi{10.1007/s10109-016-0234-x}
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(1:9, each = 3),
#'   year = rep(2020:2022, times = 9),
#'   value = c(
#'     1, 2, 3, 4, 3, 5, 6, 7, 6, 8, 9, 10, 11, 10,
#'     12, 13, 14, 13, 15, 16, 17, 18, 17, 19, 20, 21, 20
#'   )
#' )
#' grid <- sf::st_sf(
#'   id = 1:9,
#'   geometry = sf::st_make_grid(
#'     sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 3, ymax = 3)),
#'     n = c(3, 3)
#'   )
#' ) |>
#'   dplyr::mutate(
#'     nb = sfdep::st_contiguity(geometry),
#'     wt = sfdep::st_weights(nb)
#'   )
#' spatial <- spatial_markov(panel, id, year, value, geometry = grid, k = 3)
#' homogeneity_test(spatial)
#' @export
homogeneity_test <- function(x, ...) {
  UseMethod("homogeneity_test")
}

#' @export
homogeneity_test.grd_spatial_markov <- function(x, ...) {
  mats <- lapply(x$lag_states, function(lag_class) {
    transition_matrix(x, type = "count", lag_class = lag_class)
  })
  names(mats) <- x$lag_states
  homogeneity_test(mats)
}

#' @export
homogeneity_test.list <- function(x, ...) {
  if (length(x) < 2) {
    stop("Homogeneity tests need at least two regimes.", call. = FALSE)
  }
  mats <- lapply(x, function(m) {
    m <- as.matrix(m)
    if (!is.numeric(m)) {
      stop(
        "Regime matrices must contain numeric transition counts.",
        call. = FALSE
      )
    }
    storage.mode(m) <- "double"
    m
  })
  dims <- unique(lapply(mats, dim))
  if (length(dims) != 1 || dims[[1]][1] != dims[[1]][2]) {
    stop(
      "All regime matrices must be square and share the same dimensions.",
      call. = FALSE
    )
  }
  if (any(vapply(mats, function(m) any(!is.finite(m)), logical(1)))) {
    stop(
      "Regime matrices must contain finite transition counts.",
      call. = FALSE
    )
  }
  if (any(vapply(mats, function(m) any(m < 0), logical(1)))) {
    stop(
      "Regime matrices must contain non-negative transition counts.",
      call. = FALSE
    )
  }
  if (any(vapply(mats, function(m) any(m != floor(m)), logical(1)))) {
    stop(
      "Regime matrices must contain whole-number transition counts.",
      call. = FALSE
    )
  }
  if (any(vapply(mats, function(m) sum(m) == 0, logical(1)))) {
    stop(
      "Each regime matrix must contain at least one transition.",
      call. = FALSE
    )
  }
  bb <- .grd_homogeneity(mats)
  kb <- .grd_kullback(mats)
  tibble::tibble(
    test = c("chi2", "likelihood_ratio", "kullback"),
    statistic = c(bb$Q, bb$LR, kb$statistic),
    df = c(bb$dof, bb$dof, kb$dof),
    p_value = c(bb$Q_p_value, bb$LR_p_value, kb$p_value)
  )
}

# Bickenbach & Bode (2003) degrees of freedom: for each origin state,
# (regimes with transitions out of it - 1) * (destinations reached from it in
# the pooled matrix - 1). An origin state with no transitions in any regime
# contributes nothing to the statistics, so it contributes no degrees of
# freedom; giddy.markov.Homogeneity_Results counts it as +1.
.grd_homogeneity_dof <- function(mats) {
  a_i <- rowSums(Reduce(`+`, mats) > 0)
  b_i <- Reduce(`+`, lapply(mats, function(m) rowSums(m) > 0))
  as.integer(sum(pmax(b_i - 1, 0) * pmax(a_i - 1, 0)))
}

# Pearson Q and likelihood-ratio homogeneity statistics with the
# Bickenbach & Bode (2003) degrees-of-freedom adjustment, mirroring
# giddy.markov.Homogeneity_Results.
.grd_homogeneity <- function(mats) {
  total <- Reduce(`+`, mats)
  n_i <- rowSums(total)
  p_ij <- total / ifelse(n_i == 0, 1, n_i)
  den <- p_ij + (p_ij == 0)

  Q <- 0
  LR <- 0
  for (nijm in mats) {
    nim <- rowSums(nijm)
    p_ijm <- nijm / ifelse(nim == 0, 1, nim)
    Q <- Q + sum(nim * (p_ijm - p_ij)^2 / den)
    mask <- (nijm > 0) & (p_ij > 0)
    ratio <- ifelse(mask, p_ijm / p_ij, 1)
    LR <- LR + sum(nijm * log(ratio))
  }
  LR <- 2 * LR
  dof <- .grd_homogeneity_dof(mats)
  list(
    Q = Q,
    LR = LR,
    dof = dof,
    Q_p_value = stats::pchisq(Q, dof, lower.tail = FALSE),
    LR_p_value = stats::pchisq(LR, dof, lower.tail = FALSE)
  )
}

# Kullback information test of conditional homogeneity. The stratum-specific
# nuisance margins are origin-state (row) totals. giddy <= 2.3.9 instead sums
# terminal-state columns here (fixed upstream in pysal/giddy#260); the
# distinction vanishes for flow-balanced transition tables but not for
# aggregated panels with endpoint imbalance.
#
# With origin margins, t1 - t4 - t2 + t3 expands to
# 2 * sum(n_ijm * log(p_ijm / p_ij)), the likelihood-ratio statistic, i.e. a
# sum over origin states of G-tests of regime x destination independence.
# Each such G-test has (regimes observed - 1) * (destinations observed - 1)
# degrees of freedom, so the Bickenbach & Bode count applies, not the
# unadjusted r * (s - 1) * (r - 1) used by giddy (pysal/giddy#265).
.grd_kullback <- function(mats) {
  xlogx <- function(v) sum(v * log(ifelse(v == 0, 1, v)))

  t1 <- 2 * sum(vapply(mats, xlogx, numeric(1)))
  pooled <- Reduce(`+`, mats)
  t2 <- 2 * xlogx(pooled)
  t3 <- 2 * xlogx(rowSums(pooled))
  t4 <- 2 * sum(vapply(mats, function(m) xlogx(rowSums(m)), numeric(1)))

  statistic <- max(0, t1 - t4 - t2 + t3)
  dof <- .grd_homogeneity_dof(mats)
  list(
    statistic = statistic,
    dof = dof,
    p_value = stats::pchisq(statistic, dof, lower.tail = FALSE)
  )
}
