.grd_col_name <- function(arg) {
  rlang::as_name(rlang::ensym(arg))
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

.grd_is_sf <- function(x) {
  inherits(x, "sf")
}

.grd_drop_geometry <- function(x) {
  if (.grd_is_sf(x)) {
    sf::st_drop_geometry(x)
  } else {
    x
  }
}

.grd_state_labels <- function(k, labels = NULL) {
  if (is.null(labels)) {
    paste0("Q", seq_len(k))
  } else {
    labels
  }
}

.grd_quantile_breaks <- function(x, k = 5) {
  stats::quantile(x, probs = seq(0, 1, length.out = k + 1), na.rm = TRUE, type = 7)
}

.grd_break_table <- function(breaks, labels = NULL, type = "value") {
  breaks <- unique(as.numeric(breaks))
  labels <- .grd_state_labels(length(breaks) - 1, labels)
  tibble::tibble(
    class = factor(labels, levels = labels, ordered = TRUE),
    lower = breaks[-length(breaks)],
    upper = breaks[-1],
    type = type
  )
}

.grd_cut <- function(x, breaks, labels = NULL) {
  breaks <- unique(as.numeric(breaks))
  if (length(breaks) < 2) {
    stop("At least two unique break values are required.", call. = FALSE)
  }
  n_classes <- length(breaks) - 1
  labels <- .grd_state_labels(n_classes, labels)
  if (length(labels) != n_classes) {
    stop("`labels` must have one fewer value than `breaks`.", call. = FALSE)
  }
  cut(
    x,
    breaks = breaks,
    labels = labels,
    include.lowest = TRUE,
    ordered_result = TRUE
  )
}

.grd_ntile_factor <- function(x, k, labels = NULL) {
  labels <- .grd_state_labels(k, labels)
  out <- dplyr::ntile(x, k)
  factor(labels[out], levels = labels, ordered = TRUE)
}

.grd_prob_table <- function(counts) {
  probs <- prop.table(counts, margin = 1)
  probs[is.nan(probs)] <- NA_real_
  probs
}

.grd_complete_matrix_tibble <- function(transitions, state_levels) {
  transitions |>
    dplyr::count(.data$from_state, .data$to_state, name = "n") |>
    tidyr::complete(
      from_state = factor(state_levels, levels = state_levels, ordered = TRUE),
      to_state = factor(state_levels, levels = state_levels, ordered = TRUE),
      fill = list(n = 0L)
    ) |>
    dplyr::group_by(.data$from_state) |>
    dplyr::mutate(probability = if (sum(.data$n) > 0) .data$n / sum(.data$n) else NA_real_) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      transition = paste(.data$from_state, "->", .data$to_state),
      .after = "to_state"
    )
}

.grd_stationary <- function(P, tol = 1e-12) {
  P <- as.matrix(P)
  if (nrow(P) != ncol(P)) {
    stop("Transition matrix must be square.", call. = FALSE)
  }
  if (anyNA(P)) {
    return(rep(NA_real_, nrow(P)))
  }
  eig <- eigen(t(P))
  idx <- which.min(Mod(eig$values - 1))
  v <- Re(eig$vectors[, idx])
  if (sum(v) < 0) v <- -v
  v[abs(v) < tol] <- 0
  v / sum(v)
}
