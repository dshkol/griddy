#' Estimate Spatial Markov Transition Dynamics
#'
#' Estimates transition matrices conditioned on the class of each unit's spatial
#' lag at the start of the transition period.
#'
#' @param data A long data frame or `sf` object.
#' @param id,time,value Columns identifying spatial unit, time, and value.
#' @param geometry An `sf` tibble with one row per spatial unit (a single time
#'   slice's geography), carrying `nb` and `wt` list-columns produced by
#'   `sfdep::st_contiguity()` and `sfdep::st_weights()`. The preferred input.
#' @param listw A row-standardized `spdep` `listw` object. Accepted for
#'   compatibility with prior workflows; use `geometry` for new code.
#' @param nb A `spdep` neighbor list, used only when both `geometry` and
#'   `listw` are `NULL`. Converted with `spdep::nb2listw(style = "W")`.
#' @param k Number of value classes.
#' @param lag_k Number of spatial-lag classes.
#' @param class_method Value classification method passed to [classify_dynamics()].
#' @param zero.policy Passed to `spdep` lag/weight helpers.
#'
#' @return A `grd_spatial_markov` object.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(1:4, each = 3),
#'   year = rep(2020:2022, times = 4),
#'   value = c(1, 2, 3, 2, 3, 4, 4, 3, 5, 5, 6, 7)
#' )
#'
#' grid <- sf::st_sf(
#'   id = 1:4,
#'   geometry = sf::st_make_grid(
#'     sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 2, ymax = 2)),
#'     n = c(2, 2)
#'   )
#' ) |>
#'   dplyr::mutate(
#'     nb = sfdep::st_contiguity(geometry),
#'     wt = sfdep::st_weights(nb)
#'   )
#'
#' spatial <- spatial_markov(panel, id, year, value, geometry = grid, k = 2)
#'
#' spatial
#' lag_intervals(spatial)
#' transition_matrix(spatial, "count", lag_class = "Q1")
#' @export
spatial_markov <- function(data, id, time, value,
                           geometry = NULL,
                           listw = NULL,
                           nb = NULL,
                           k = 5,
                           lag_k = k,
                           class_method = c("pooled_quantile", "time_quantile", "fixed"),
                           zero.policy = TRUE) {
  class_method <- match.arg(class_method)
  id <- rlang::ensym(id)
  time <- rlang::ensym(time)
  value <- rlang::ensym(value)

  if (!is.null(geometry)) {
    if (!"nb" %in% names(geometry)) {
      stop(
        "`geometry` must carry an `nb` list-column. ",
        "Build one with `sfdep::st_contiguity()`.",
        call. = FALSE
      )
    }
    nb_obj <- geometry$nb
    if ("wt" %in% names(geometry)) {
      listw <- spdep::nb2listw(
        nb_obj,
        glist = geometry$wt,
        style = "W",
        zero.policy = zero.policy
      )
    } else {
      listw <- spdep::nb2listw(nb_obj, style = "W", zero.policy = zero.policy)
    }
  } else if (is.null(listw)) {
    if (is.null(nb)) {
      stop("Provide `geometry`, `listw`, or `nb`.", call. = FALSE)
    }
    listw <- spdep::nb2listw(nb, style = "W", zero.policy = zero.policy)
  }

  flat <- .grd_drop_geometry(data)
  id_name <- rlang::as_name(id)
  time_name <- rlang::as_name(time)
  value_name <- rlang::as_name(value)

  id_order <- flat |>
    dplyr::arrange(!!time, !!id) |>
    dplyr::filter(!!time == min(!!time, na.rm = TRUE)) |>
    dplyr::pull(!!id)

  n_units <- length(id_order)
  if (length(listw$neighbours) != n_units) {
    stop("The weights object length must match the number of spatial units.", call. = FALSE)
  }

  value_classes <- classify_dynamics(
    flat,
    id = !!id,
    time = !!time,
    value = !!value,
    method = class_method,
    k = k
  )
  value_intervals <- attr(value_classes, "class_intervals")
  value_classes <- value_classes |>
    .grd_drop_geometry() |>
    dplyr::select(!!id, !!time, "class") |>
    dplyr::rename(value_class = "class")

  lag_panel <- flat |>
    dplyr::select(!!id, !!time, !!value) |>
    dplyr::group_by(!!time) |>
    dplyr::group_modify(function(.x, .y) {
      arranged <- .x |>
        dplyr::arrange(match(.data[[id_name]], id_order))
      if (!identical(as.character(arranged[[id_name]]), as.character(id_order))) {
        stop("Each time period must contain the same IDs as the weights object order.", call. = FALSE)
      }
      arranged$spatial_lag <- spdep::lag.listw(listw, arranged[[value_name]], zero.policy = zero.policy)
      arranged
    }) |>
    dplyr::ungroup()

  lag_breaks <- .grd_quantile_breaks(lag_panel$spatial_lag, lag_k)
  lag_intervals <- .grd_break_table(lag_breaks, type = "spatial_lag")

  lag_panel <- lag_panel |>
    dplyr::mutate(lag_class = .grd_cut(.data$spatial_lag, lag_breaks)) |>
    dplyr::left_join(value_classes, by = stats::setNames(c(id_name, time_name), c(id_name, time_name)))

  state_levels <- levels(value_classes$value_class)
  lag_levels <- levels(lag_panel$lag_class)

  transitions <- lag_panel |>
    dplyr::arrange(!!id, !!time) |>
    dplyr::group_by(!!id) |>
    dplyr::mutate(
      to_state = dplyr::lead(.data$value_class),
      to_time = dplyr::lead(!!time)
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$to_state)) |>
    dplyr::transmute(
      id = !!id,
      from_time = !!time,
      to_time = .data$to_time,
      lag_class = factor(as.character(.data$lag_class), levels = lag_levels, ordered = TRUE),
      from_state = factor(as.character(.data$value_class), levels = state_levels, ordered = TRUE),
      to_state = factor(as.character(.data$to_state), levels = state_levels, ordered = TRUE),
      spatial_lag = .data$spatial_lag
    ) |>
    dplyr::mutate(
      transition = paste(.data$from_state, "->", .data$to_state),
      .after = "to_state"
    )

  matrix_data <- transitions |>
    dplyr::count(.data$lag_class, .data$from_state, .data$to_state, name = "n") |>
    tidyr::complete(
      lag_class = factor(lag_levels, levels = lag_levels, ordered = TRUE),
      from_state = factor(state_levels, levels = state_levels, ordered = TRUE),
      to_state = factor(state_levels, levels = state_levels, ordered = TRUE),
      fill = list(n = 0L)
    ) |>
    dplyr::group_by(.data$lag_class, .data$from_state) |>
    dplyr::mutate(probability = if (sum(.data$n) > 0) .data$n / sum(.data$n) else NA_real_) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      transition = paste(.data$from_state, "->", .data$to_state),
      .after = "to_state"
    ) |>
    dplyr::left_join(
      lag_intervals |>
        dplyr::rename(lag_class = "class", lag_lower = "lower", lag_upper = "upper") |>
        dplyr::select("lag_class", "lag_lower", "lag_upper"),
      by = "lag_class"
    )

  out <- list(
    transitions = transitions,
    matrix = matrix_data,
    lag_panel = lag_panel,
    states = state_levels,
    lag_states = lag_levels,
    lag_breaks = lag_breaks,
    class_intervals = value_intervals,
    lag_intervals = lag_intervals,
    id = id_name,
    time = time_name,
    value = value_name,
    listw = listw
  )
  class(out) <- "grd_spatial_markov"
  out
}

#' @export
print.grd_spatial_markov <- function(x, ...) {
  cat("<grd_spatial_markov>\n")
  cat(length(x$states), "states,", length(x$lag_states), "lag states,", nrow(x$transitions), "observed transitions\n")
  print(x$matrix)
  invisible(x)
}

#' @export
as.data.frame.grd_spatial_markov <- function(x, ...) {
  as.data.frame(x$matrix, ...)
}
