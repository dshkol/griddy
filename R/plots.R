#' Plot A Transition Matrix
#'
#' @param x A `grd_markov` object.
#'
#' @return A `ggplot` object.
#' @export
plot_transition_matrix <- function(x) {
  stopifnot(inherits(x, "grd_markov"))
  x$matrix |>
    ggplot2::ggplot(ggplot2::aes(.data$to_state, .data$from_state, fill = .data$probability)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.35) +
    ggplot2::geom_text(ggplot2::aes(label = scales::percent(.data$probability, accuracy = 1)), na.rm = TRUE, size = 3) +
    ggplot2::scale_fill_viridis_c(labels = scales::percent, na.value = "grey90") +
    ggplot2::labs(x = "To state", y = "From state", fill = "Probability")
}

#' Plot Spatial Markov Matrices
#'
#' @param x A `grd_spatial_markov` object.
#'
#' @return A `ggplot` object.
#' @export
plot_spatial_markov <- function(x) {
  stopifnot(inherits(x, "grd_spatial_markov"))
  x$matrix |>
    ggplot2::ggplot(ggplot2::aes(.data$to_state, .data$from_state, fill = .data$probability)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.3) +
    ggplot2::facet_wrap(ggplot2::vars(.data$lag_class)) +
    ggplot2::scale_fill_viridis_c(labels = scales::percent, na.value = "grey90") +
    ggplot2::labs(x = "To state", y = "From state", fill = "Probability")
}

#' Plot Rank Mobility
#'
#' @param x A `grd_rank_mobility` object returned by [rank_mobility()].
#'
#' @return A `ggplot` object.
#' @export
plot_rank_mobility <- function(x) {
  if (!inherits(x, "sf")) {
    stop("`x` must retain geometry to draw a rank mobility map.", call. = FALSE)
  }
  ggplot2::ggplot(x) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data$rank_change), color = "white", linewidth = 0.2) +
    ggplot2::scale_fill_gradient2(
      low = "#b2182b",
      mid = "grey95",
      high = "#2166ac",
      midpoint = 0
    ) +
    ggplot2::labs(fill = "Rank gain")
}
