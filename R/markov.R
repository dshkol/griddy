#' Estimate Classic Markov Transition Dynamics
#'
#' Estimates transition counts and probabilities between adjacent periods for a
#' classified long panel.
#'
#' @param classes A classified data frame from [classify_dynamics()] or any data
#'   frame with ID, time, and state columns.
#' @param id,time,state Columns identifying spatial unit, time, and state.
#'
#' @return A `grd_markov` object.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(letters[1:4], each = 3),
#'   year = rep(2020:2022, times = 4),
#'   value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
#' )
#'
#' classes <- classify_dynamics(panel, id, year, value, k = 3)
#' markov <- markov_dynamics(classes, id, year, class)
#'
#' markov
#' transition_matrix(markov)
#' steady_state(markov)
#' @export
markov_dynamics <- function(classes, id, time, state = class) {
  id <- rlang::ensym(id)
  time <- rlang::ensym(time)
  state <- rlang::ensym(state)

  data <- .grd_drop_geometry(classes)
  state_vec <- dplyr::pull(data, !!state)
  state_levels <- if (is.factor(state_vec)) levels(state_vec) else sort(unique(stats::na.omit(as.character(state_vec))))

  transitions <- data |>
    dplyr::arrange(!!id, !!time) |>
    dplyr::group_by(!!id) |>
    dplyr::mutate(
      to_state = dplyr::lead(!!state),
      to_time = dplyr::lead(!!time)
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$to_state)) |>
    dplyr::transmute(
      id = !!id,
      from_time = !!time,
      to_time = .data$to_time,
      from_state = factor(as.character(!!state), levels = state_levels, ordered = TRUE),
      to_state = factor(as.character(.data$to_state), levels = state_levels, ordered = TRUE)
    ) |>
    dplyr::mutate(
      transition = paste(.data$from_state, "->", .data$to_state),
      .after = "to_state"
    )

  counts <- table(transitions$from_state, transitions$to_state)
  probabilities <- .grd_prob_table(counts)

  matrix_data <- .grd_complete_matrix_tibble(transitions, state_levels)

  out <- list(
    transitions = transitions,
    matrix = matrix_data,
    counts = counts,
    probabilities = probabilities,
    states = state_levels,
    class_intervals = attr(classes, "class_intervals"),
    id = rlang::as_name(id),
    time = rlang::as_name(time),
    state = rlang::as_name(state)
  )
  class(out) <- "grd_markov"
  out
}

#' Extract A Transition Matrix
#'
#' @param x A `grd_markov` or `grd_spatial_markov` object.
#' @param type `"probability"` or `"count"`.
#' @param lag_class Optional lag class for `grd_spatial_markov`.
#'
#' @return A matrix.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(letters[1:4], each = 3),
#'   year = rep(2020:2022, times = 4),
#'   value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
#' )
#' markov <- panel |>
#'   classify_dynamics(id, year, value, k = 3) |>
#'   markov_dynamics(id, year, class)
#'
#' transition_matrix(markov, "count")
#' @export
transition_matrix <- function(x, type = c("probability", "count"), lag_class = NULL) {
  type <- match.arg(type)
  UseMethod("transition_matrix")
}

#' @export
transition_matrix.grd_markov <- function(x, type = c("probability", "count"), lag_class = NULL) {
  type <- match.arg(type)
  if (type == "count") x$counts else x$probabilities
}

#' @export
transition_matrix.grd_spatial_markov <- function(x, type = c("probability", "count"), lag_class = NULL) {
  type <- match.arg(type)
  if (is.null(lag_class)) {
    stop("`lag_class` is required for spatial Markov objects.", call. = FALSE)
  }
  target_lag_class <- as.character(lag_class)
  dat <- x$matrix |>
    dplyr::filter(as.character(.data$lag_class) == .env$target_lag_class)
  if (nrow(dat) == 0) {
    stop("No transition matrix found for `lag_class`.", call. = FALSE)
  }
  value <- if (type == "count") "n" else "probability"
  wide <- dat |>
    dplyr::select("from_state", "to_state", value = dplyr::all_of(value)) |>
    dplyr::group_by(.data$from_state, .data$to_state) |>
    dplyr::summarise(value = dplyr::first(.data$value), .groups = "drop") |>
    tidyr::pivot_wider(names_from = "to_state", values_from = "value") |>
    tibble::column_to_rownames("from_state")
  as.matrix(wide)
}

#' Estimate Stationary Distribution
#'
#' @param x A `grd_markov` object or transition probability matrix.
#'
#' @return A numeric vector.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' prob <- matrix(c(0.8, 0.2, 0.3, 0.7), nrow = 2, byrow = TRUE)
#' steady_state(prob)
#' @export
steady_state <- function(x) {
  UseMethod("steady_state")
}

#' @export
steady_state.grd_markov <- function(x) {
  out <- .grd_stationary(x$probabilities)
  names(out) <- x$states
  out
}

#' @export
steady_state.matrix <- function(x) {
  out <- .grd_stationary(x)
  names(out) <- rownames(x)
  out
}

#' @export
print.grd_markov <- function(x, ...) {
  cat("<grd_markov>\n")
  cat(length(x$states), "states,", nrow(x$transitions), "observed transitions\n")
  print(x$probabilities)
  invisible(x)
}

#' @export
as.data.frame.grd_markov <- function(x, ...) {
  as.data.frame(x$matrix, ...)
}

#' Class Intervals Used By A griddy Object
#'
#' @param x A griddy result object.
#' @param ... Reserved for future methods.
#'
#' @return A tibble of class intervals when available.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(id = rep(1:3, each = 2), year = rep(2020:2021, 3), value = 1:6)
#' classes <- classify_dynamics(panel, id, year, value, k = 3)
#' class_intervals(classes)
#' @export
class_intervals <- function(x, ...) {
  UseMethod("class_intervals")
}

#' @export
class_intervals.grd_classes <- function(x, ...) {
  attr(x, "class_intervals")
}

#' @export
class_intervals.grd_markov <- function(x, ...) {
  x$class_intervals
}

#' @export
class_intervals.grd_spatial_markov <- function(x, ...) {
  x$class_intervals
}

#' Spatial Lag Intervals Used By A Spatial Markov Object
#'
#' @param x A `grd_spatial_markov` object.
#'
#' @return A tibble of spatial-lag class intervals.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(1:4, each = 2),
#'   year = rep(2020:2021, times = 4),
#'   value = c(1, 2, 2, 3, 4, 3, 5, 6)
#' )
#' nb <- spdep::cell2nb(2, 2)
#' spatial <- spatial_markov(panel, id, year, value, nb = nb, k = 2)
#' lag_intervals(spatial)
#' @export
lag_intervals <- function(x) {
  UseMethod("lag_intervals")
}

#' @export
lag_intervals.grd_spatial_markov <- function(x) {
  x$lag_intervals
}
