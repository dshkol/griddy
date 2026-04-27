#' Classify Longitudinal Values For Distribution Dynamics
#'
#' Converts numeric values in a long panel into ordered classes suitable for
#' transition analysis.
#'
#' @param data A data frame or `sf` object in long format.
#' @param id,time,value Columns identifying spatial unit, time, and value.
#' @param method Classification method. `"pooled_quantile"` uses one set of
#'   quantile breaks across all periods. `"time_quantile"` uses period-specific
#'   ranks. `"fixed"` uses user-supplied `breaks`. `"existing"` treats `value`
#'   as an already classified state.
#' @param k Number of quantile classes.
#' @param breaks Breaks for `method = "fixed"`.
#' @param labels Optional class labels.
#'
#' @return A data frame or `sf` object with a `class` column and class
#'   `grd_classes`.
#'
#' @examplesIf identical(Sys.getenv("IN_PKGDOWN"), "true")
#' panel <- data.frame(
#'   id = rep(letters[1:4], each = 3),
#'   year = rep(2020:2022, times = 4),
#'   value = c(8, 9, 11, 10, 12, 13, 15, 14, 16, 20, 22, 25)
#' )
#'
#' classes <- classify_dynamics(panel, id, year, value, k = 3)
#' classes
#' class_intervals(classes)
#' @export
classify_dynamics <- function(data, id, time, value,
                              method = c("pooled_quantile", "time_quantile", "fixed", "existing"),
                              k = 5,
                              breaks = NULL,
                              labels = NULL) {
  method <- match.arg(method)
  id <- rlang::ensym(id)
  time <- rlang::ensym(time)
  value <- rlang::ensym(value)

  value_vec <- dplyr::pull(data, !!value)

  out <- switch(
    method,
    pooled_quantile = {
      q_breaks <- .grd_quantile_breaks(value_vec, k)
      data |>
        dplyr::mutate(class = .grd_cut(!!value, q_breaks, labels = labels))
    },
    time_quantile = {
      data |>
        dplyr::group_by(!!time) |>
        dplyr::mutate(class = .grd_ntile_factor(!!value, k, labels = labels)) |>
        dplyr::ungroup()
    },
    fixed = {
      if (is.null(breaks)) {
        stop("`breaks` is required when `method = \"fixed\"`.", call. = FALSE)
      }
      data |>
        dplyr::mutate(class = .grd_cut(!!value, breaks, labels = labels))
    },
    existing = {
      state_labels <- labels %||% sort(unique(stats::na.omit(as.character(value_vec))))
      data |>
        dplyr::mutate(class = factor(as.character(!!value), levels = state_labels, ordered = TRUE))
    }
  )

  out <- out |>
    dplyr::arrange(!!id, !!time)

  class(out) <- unique(c("grd_classes", class(out)))
  attr(out, "id") <- rlang::as_name(id)
  attr(out, "time") <- rlang::as_name(time)
  attr(out, "value") <- rlang::as_name(value)
  attr(out, "method") <- method
  attr(out, "k") <- k
  attr(out, "breaks") <- if (method == "pooled_quantile") .grd_quantile_breaks(value_vec, k) else breaks
  attr(out, "class_intervals") <- if (method %in% c("pooled_quantile", "fixed")) {
    .grd_break_table(attr(out, "breaks"), labels = labels, type = "value")
  } else {
    NULL
  }
  out
}

#' @export
print.grd_classes <- function(x, ...) {
  cat("<grd_classes>\n")
  NextMethod()
}

#' @export
as.data.frame.grd_classes <- function(x, ...) {
  class(x) <- setdiff(class(x), "grd_classes")
  as.data.frame(x, ...)
}
