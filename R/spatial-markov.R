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
#'   Its rows are matched to units by the `geometry_id` column, or by a column
#'   with the same name as `id`, so their order does not matter.
#' @param geometry_id The column of `geometry` that holds unit ids, when its
#'   name differs from `id`. Its values must match the values of `id` one to
#'   one.
#' @param listw A row-standardized `spdep` `listw` object. Accepted for
#'   compatibility with prior workflows; use `geometry` for new code. Its rows
#'   are matched to units by id when its region ids are the values of `id`,
#'   as with `spdep::poly2nb(x, row.names = x$id)`, and by position otherwise.
#' @param nb A `spdep` neighbor list, used only when both `geometry` and
#'   `listw` are `NULL`. Converted with `spdep::nb2listw(style = "W")`. Its
#'   rows are matched to units as for `listw`.
#' @param k Number of value classes.
#' @param lag_k Number of spatial-lag classes.
#' @param class_method Value classification method passed to [classify_dynamics()].
#' @param zero.policy Passed to `spdep` lag/weight helpers.
#'
#' @return A `grd_spatial_markov` object.
#'
#' @section Matching weights to units:
#' Each row of `geometry`, `listw`, or `nb` describes one unit. The neighbor
#' lists refer to rows by position, so build them after the last filter or
#' reorder of the geography. `spatial_markov()` matches rows to the units in
#' `data` by id, and the row order of the weights does not matter. It stops
#' when the weights' ids have missing or duplicated values or do not match the
#' values of `id` one to one.
#'
#' When the weights carry no usable ids, rows are matched by position: the
#' first row is taken to be the unit with the smallest `id`, the second row
#' the next, and so on. This happens when `geometry` has neither a
#' `geometry_id` column nor a column named like `id`, and when the region ids
#' of `listw` or `nb` are not the values of `id`. `spatial_markov()` warns in
#' that case, because weights in any other row order give units the wrong
#' neighbors without an error. Before griddy 0.2.0, rows were always matched
#' by position.
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
                           geometry_id = NULL,
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
  geometry_id <- rlang::enquo(geometry_id)

  flat <- .grd_drop_geometry(data)
  id_name <- rlang::as_name(id)
  time_name <- rlang::as_name(time)
  value_name <- rlang::as_name(value)
  panel_ids <- unique(flat[[id_name]])
  id_order <- NULL

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

    geometry_id_name <- if (rlang::quo_is_null(geometry_id)) {
      id_name
    } else {
      rlang::as_name(geometry_id)
    }
    if (geometry_id_name %in% names(geometry)) {
      id_order <- .grd_check_weight_ids(
        geometry[[geometry_id_name]],
        panel_ids,
        label = paste0("`geometry$", geometry_id_name, "`"),
        id_name = id_name
      )
    } else if (!rlang::quo_is_null(geometry_id)) {
      stop("`geometry` has no column `", geometry_id_name, "`.", call. = FALSE)
    } else {
      warning(
        "`geometry` has no `", id_name, "` column, so its rows were matched ",
        "to units by position, in ascending order of `", id_name, "`. ",
        "Pass `geometry_id` to match them by id.",
        call. = FALSE
      )
    }
  } else {
    if (!rlang::quo_is_null(geometry_id)) {
      stop("`geometry_id` applies only to `geometry`.", call. = FALSE)
    }
    weights_arg <- "listw"
    if (is.null(listw)) {
      if (is.null(nb)) {
        stop("Provide `geometry`, `listw`, or `nb`.", call. = FALSE)
      }
      weights_arg <- "nb"
      listw <- spdep::nb2listw(nb, style = "W", zero.policy = zero.policy)
    }

    region_ids <- attr(listw$neighbours, "region.id")
    if (.grd_ids_match(region_ids, panel_ids)) {
      id_order <- region_ids
    } else {
      warning(
        "The region ids of `", weights_arg, "` do not match `", id_name,
        "`, so its rows were matched to units by position, in ascending ",
        "order of `", id_name, "`. To match them by id, build the neighbor ",
        "list with region ids from `", id_name, "`, for example ",
        "`spdep::poly2nb(x, row.names = x$", id_name, ")`.",
        call. = FALSE
      )
    }
  }

  if (is.null(id_order)) {
    id_order <- flat |>
      dplyr::arrange(!!time, !!id) |>
      dplyr::filter(!!time == min(!!time, na.rm = TRUE)) |>
      dplyr::pull(!!id)
  }

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

  # Spatial lags are computed with periods as columns and units in the row
  # order of the weights, then the result is sorted back by time and id.
  lag_panel <- flat |>
    dplyr::select(!!id, !!time, !!value) |>
    dplyr::arrange(!!time, match(.data[[id_name]], id_order))

  n_rows <- nrow(lag_panel)
  if (n_rows %% n_units != 0L ||
      !identical(
        match(lag_panel[[id_name]], id_order),
        rep(seq_len(n_units), n_rows %/% n_units)
      )) {
    stop("Each time period must contain every unit exactly once.", call. = FALSE)
  }

  value_matrix <- matrix(lag_panel[[value_name]], nrow = n_units)
  lag_panel$spatial_lag <- as.vector(
    spdep::lag.listw(listw, value_matrix, zero.policy = zero.policy)
  )
  lag_panel <- lag_panel |>
    dplyr::arrange(!!time, !!id) |>
    dplyr::relocate(!!time)

  lag_breaks <- .grd_quantile_breaks(lag_panel$spatial_lag, lag_k)
  lag_intervals <- .grd_break_table(lag_breaks, type = "spatial_lag")

  lag_panel <- lag_panel |>
    dplyr::mutate(lag_class = .grd_cut(.data$spatial_lag, lag_breaks)) |>
    dplyr::left_join(value_classes, by = stats::setNames(c(id_name, time_name), c(id_name, time_name)))

  state_levels <- levels(value_classes$value_class)
  lag_levels <- levels(lag_panel$lag_class)

  transitions <- lag_panel |>
    dplyr::arrange(!!id, !!time)
  unit <- transitions[[id_name]]

  transitions <- transitions |>
    dplyr::mutate(
      to_state = .grd_lead_within(.data$value_class, unit),
      to_time = .grd_lead_within(!!time, unit)
    ) |>
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

.grd_ids_match <- function(ids, panel_ids) {
  !is.null(ids) &&
    length(ids) == length(panel_ids) &&
    !anyNA(ids) &&
    !anyDuplicated(ids) &&
    !anyNA(match(panel_ids, ids))
}

.grd_check_weight_ids <- function(ids, panel_ids, label, id_name) {
  if (anyNA(ids)) {
    stop(label, " has missing values.", call. = FALSE)
  }
  if (anyDuplicated(ids)) {
    stop(
      label, " has duplicated values: ", .grd_show_ids(ids[duplicated(ids)]),
      ". `geometry` must have one row per unit.",
      call. = FALSE
    )
  }
  unmatched <- panel_ids[is.na(match(panel_ids, ids))]
  if (length(unmatched) > 0L) {
    stop(.grd_not_in(unmatched, paste0("`", id_name, "`"), label), call. = FALSE)
  }
  unmatched <- ids[is.na(match(ids, panel_ids))]
  if (length(unmatched) > 0L) {
    stop(.grd_not_in(unmatched, label, paste0("`", id_name, "`")), call. = FALSE)
  }
  ids
}

.grd_not_in <- function(x, from, to) {
  n <- length(unique(x))
  paste0(
    if (n == 1L) "1 value of " else paste(n, "values of "), from,
    if (n == 1L) " is" else " are", " not in ", to, ": ",
    .grd_show_ids(x), "."
  )
}

.grd_show_ids <- function(x, n = 3L) {
  x <- unique(as.character(x))
  shown <- paste0("\"", x[seq_len(min(n, length(x)))], "\"", collapse = ", ")
  if (length(x) > n) paste0(shown, ", ...") else shown
}
