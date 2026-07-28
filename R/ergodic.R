#' Expected Sojourn Times
#'
#' Computes the expected number of consecutive periods a unit remains in each
#' class once it enters it, `1 / (1 - p_ii)`. Absorbing classes (`p_ii = 1`)
#' have infinite sojourn times.
#'
#' @param x A `grd_markov` object or a square transition probability matrix.
#'
#' @return A named numeric vector of expected sojourn times, one per class.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
#' sojourn_time(prob)
#' @export
sojourn_time <- function(x) {
  UseMethod("sojourn_time")
}

#' @export
sojourn_time.grd_markov <- function(x) {
  out <- sojourn_time(.grd_check_prob_matrix(x$probabilities))
  names(out) <- x$states
  out
}

#' @export
sojourn_time.default <- function(x) {
  P <- .grd_check_prob_matrix(x)
  pii <- diag(P)
  out <- ifelse(pii >= 1, Inf, 1 / (1 - pii))
  names(out) <- rownames(P)
  out
}

#' Mean First-Passage Times
#'
#' Computes the matrix of mean first-passage times for an ergodic transition
#' probability matrix following Kemeny and Snell: entry `[i, j]` is the
#' expected number of transitions to reach class `j` for the first time
#' starting from class `i`. Diagonal entries are mean recurrence times,
#' the reciprocal of the stationary distribution.
#'
#' @param x A `grd_markov` object or a square transition probability matrix.
#'   The underlying chain must be ergodic (irreducible and aperiodic);
#'   matrices with absorbing or unreachable classes are rejected.
#'
#' @return A square numeric matrix of mean first-passage times.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
#' first_passage(prob)
#' @export
first_passage <- function(x) {
  UseMethod("first_passage")
}

#' @export
first_passage.grd_markov <- function(x) {
  out <- first_passage(.grd_check_prob_matrix(x$probabilities))
  dimnames(out) <- list(x$states, x$states)
  out
}

#' @export
first_passage.default <- function(x) {
  P <- .grd_check_prob_matrix(x)
  k <- nrow(P)
  stat <- .grd_stationary(P)
  if (anyNA(stat) || any(stat <= .Machine$double.eps)) {
    stop(
      "`first_passage()` requires an ergodic chain: every class must be ",
      "reachable and have positive stationary probability.",
      call. = FALSE
    )
  }
  A <- matrix(stat, nrow = k, ncol = k, byrow = TRUE)
  Z <- tryCatch(
    solve(diag(k) - P + A),
    error = function(e) {
      stop(
        "`first_passage()` could not invert the fundamental matrix; ",
        "the chain is not ergodic.",
        call. = FALSE
      )
    }
  )
  out <- (diag(k) - Z + matrix(1, k, k) %*% diag(diag(Z), nrow = k)) %*%
    diag(1 / stat, nrow = k)
  dimnames(out) <- dimnames(P)
  out
}

#' Markov Mobility Indices
#'
#' Computes scalar mobility indices summarising how much movement a transition
#' probability matrix implies, following Formby, Smith, and Zheng (2004) and
#' mirroring `giddy.mobility.markov_mobility()` in PySAL `giddy`.
#'
#' @param x A `grd_markov` object or a square transition probability matrix.
#' @param measure Character vector of indices to compute. Any of:
#'   * `"prais"`: the Prais--Shorrocks trace index, `(k - trace(P)) / (k - 1)`.
#'   * `"determinant"`: `1 - |det(P)|`.
#'   * `"eigen"`: the Sommers--Conlisk index, one minus the modulus of the
#'     second-largest eigenvalue of `P`.
#'   * `"bartholomew1"`: `(k - k * sum(initial * diag(P))) / (k - 1)`.
#'   * `"bartholomew2"`: the expected number of class boundaries crossed in
#'     one transition, `sum(initial[i] * P[i, j] * |i - j|) / (k - 1)`. Class
#'     distance uses the class ordering, so classes are assumed ordinal.
#' @param initial Optional initial distribution over classes used by the
#'   Bartholomew indices. Defaults to the uniform distribution, matching
#'   `giddy`.
#'
#' @return A named numeric vector with one element per requested measure.
#'   All indices are 0 for the identity matrix (no mobility) and increase
#'   with mobility.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' prob <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
#' mobility_index(prob)
#' mobility_index(prob, measure = "prais")
#' @export
mobility_index <- function(x,
                           measure = c("prais", "determinant", "eigen",
                                       "bartholomew1", "bartholomew2"),
                           initial = NULL) {
  UseMethod("mobility_index")
}

#' @export
mobility_index.grd_markov <- function(x,
                                      measure = c("prais", "determinant",
                                                  "eigen", "bartholomew1",
                                                  "bartholomew2"),
                                      initial = NULL) {
  mobility_index(.grd_check_prob_matrix(x$probabilities), measure, initial)
}

#' @export
mobility_index.default <- function(x,
                                   measure = c("prais", "determinant",
                                               "eigen", "bartholomew1",
                                               "bartholomew2"),
                                   initial = NULL) {
  measure <- match.arg(measure, several.ok = TRUE)
  P <- .grd_check_prob_matrix(x)
  k <- nrow(P)
  if (k < 2) {
    stop("Mobility indices need at least two classes.", call. = FALSE)
  }
  if (is.null(initial)) {
    initial <- rep(1 / k, k)
  }
  if (length(initial) != k || any(initial < 0) ||
      abs(sum(initial) - 1) > 1e-6) {
    stop(
      "`initial` must be a probability distribution with one entry per class.",
      call. = FALSE
    )
  }
  idx <- seq_len(k)
  vapply(measure, function(m) {
    switch(m,
      prais = (k - sum(diag(P))) / (k - 1),
      determinant = 1 - abs(det(P)),
      eigen = {
        mods <- sort(Mod(eigen(P, only.values = TRUE)$values),
                     decreasing = TRUE)
        1 - mods[2]
      },
      bartholomew1 = (k - k * sum(initial * diag(P))) / (k - 1),
      bartholomew2 = sum(initial * P * abs(outer(idx, idx, "-"))) / (k - 1)
    )
  }, numeric(1))
}

.grd_check_prob_matrix <- function(x) {
  P <- as.matrix(unclass(x))
  storage.mode(P) <- "double"
  if (nrow(P) != ncol(P)) {
    stop("Transition matrix must be square.", call. = FALSE)
  }
  if (anyNA(P)) {
    stop(
      "Transition matrix contains missing probabilities. This usually means ",
      "a class had no observed departures; refit with fewer classes.",
      call. = FALSE
    )
  }
  if (any(P < 0) || any(abs(rowSums(P) - 1) > 1e-6)) {
    stop(
      "Each row of a transition probability matrix must be non-negative ",
      "and sum to 1.",
      call. = FALSE
    )
  }
  P
}
