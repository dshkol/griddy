#' Test Homogeneity Of Transition Matrices Across Regimes
#'
#' Tests whether transition dynamics are homogeneous across regimes -- for a
#' spatial Markov object, whether the transition matrices conditioned on
#' spatial-lag class genuinely differ from the pooled matrix (Rey, Kang, and
#' Wolf 2016). Three statistics are reported: a Pearson chi-squared Q test and
#' a likelihood-ratio test with the degrees-of-freedom adjustment of
#' Bickenbach and Bald (2003), and the Kullback information test (Kullback,
#' Kupperman, and Ku 1962). All mirror their PySAL `giddy` counterparts
#' (`Spatial_Markov` homogeneity attributes and `giddy.markov.kullback()`).
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
  if (any(vapply(mats, function(m) anyNA(m) || any(m < 0), logical(1)))) {
    stop(
      "Regime matrices must contain non-negative transition counts.",
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

# Pearson Q and likelihood-ratio homogeneity statistics with the
# Bickenbach & Bald (2003) degrees-of-freedom adjustment, mirroring
# giddy.markov.Homogeneity_Results.
.grd_homogeneity <- function(mats) {
  r <- nrow(mats[[1]])
  total <- Reduce(`+`, mats)
  n_i <- rowSums(total)
  A_i <- rowSums(total > 0)
  p_ij <- total / ifelse(n_i == 0, 1, n_i)
  den <- p_ij + (p_ij == 0)

  b_i <- numeric(r)
  Q <- 0
  LR <- 0
  for (nijm in mats) {
    nim <- rowSums(nijm)
    b_i <- b_i + (nim > 0)
    p_ijm <- nijm / ifelse(nim == 0, 1, nim)
    Q <- Q + sum(nim * (p_ijm - p_ij)^2 / den)
    mask <- (nijm > 0) & (p_ij > 0)
    ratio <- ifelse(mask, p_ijm / p_ij, 1)
    LR <- LR + sum(nijm * log(ratio))
  }
  LR <- 2 * LR
  dof <- as.integer(sum((b_i - 1) * (A_i - 1)))
  list(
    Q = Q,
    LR = LR,
    dof = dof,
    Q_p_value = stats::pchisq(Q, dof, lower.tail = FALSE),
    LR_p_value = stats::pchisq(LR, dof, lower.tail = FALSE)
  )
}

# Kullback information test of conditional homogeneity, mirroring
# giddy.markov.kullback().
.grd_kullback <- function(mats) {
  s <- length(mats)
  r <- nrow(mats[[1]])
  xlogx <- function(v) sum(v * log(ifelse(v == 0, 1, v)))

  t1 <- 2 * sum(vapply(mats, xlogx, numeric(1)))
  pooled <- Reduce(`+`, mats)
  t2 <- 2 * xlogx(pooled)
  t3 <- 2 * xlogx(rowSums(pooled))
  t4 <- 2 * sum(vapply(mats, function(m) xlogx(colSums(m)), numeric(1)))

  statistic <- t1 - t4 - t2 + t3
  dof <- as.integer(r * (s - 1) * (r - 1))
  list(
    statistic = statistic,
    dof = dof,
    p_value = stats::pchisq(statistic, dof, lower.tail = FALSE)
  )
}
