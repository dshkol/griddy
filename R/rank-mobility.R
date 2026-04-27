#' Compute Rank Mobility
#'
#' Computes simple rank changes for map-ready exploratory analysis.
#'
#' @param data A long data frame or `sf` object.
#' @param id,time,value Columns identifying spatial unit, time, and value.
#' @param compare `"endpoint"` compares first and last observed periods per
#'   unit. `"adjacent"` compares adjacent periods.
#' @param descending If `TRUE`, larger values receive better ranks.
#'
#' @return A `grd_rank_mobility` data frame or `sf` object.
#' @export
rank_mobility <- function(data, id, time, value,
                          compare = c("endpoint", "adjacent"),
                          descending = TRUE) {
  compare <- match.arg(compare)
  id <- rlang::ensym(id)
  time <- rlang::ensym(time)
  value <- rlang::ensym(value)

  ranked <- data |>
    dplyr::group_by(!!time) |>
    dplyr::mutate(rank = if (descending) dplyr::min_rank(dplyr::desc(!!value)) else dplyr::min_rank(!!value)) |>
    dplyr::ungroup() |>
    dplyr::arrange(!!id, !!time)

  out <- if (compare == "endpoint") {
    ranked |>
      dplyr::group_by(!!id) |>
      dplyr::filter(!!time %in% range(!!time, na.rm = TRUE)) |>
      dplyr::mutate(
        start_time = dplyr::first(!!time),
        end_time = dplyr::last(!!time),
        start_rank = dplyr::first(.data$rank),
        end_rank = dplyr::last(.data$rank),
        rank_change = .data$start_rank - .data$end_rank,
        abs_rank_change = abs(.data$rank_change)
      ) |>
      dplyr::slice_tail(n = 1) |>
      dplyr::ungroup()
  } else {
    ranked |>
      dplyr::group_by(!!id) |>
      dplyr::mutate(
        to_time = dplyr::lead(!!time),
        to_rank = dplyr::lead(.data$rank),
        rank_change = .data$rank - .data$to_rank,
        abs_rank_change = abs(.data$rank_change)
      ) |>
      dplyr::ungroup() |>
      dplyr::filter(!is.na(.data$to_rank))
  }

  class(out) <- unique(c("grd_rank_mobility", class(out)))
  attr(out, "id") <- rlang::as_name(id)
  attr(out, "time") <- rlang::as_name(time)
  attr(out, "value") <- rlang::as_name(value)
  attr(out, "compare") <- compare
  out
}

#' @export
print.grd_rank_mobility <- function(x, ...) {
  cat("<grd_rank_mobility>\n")
  NextMethod()
}

#' @export
as.data.frame.grd_rank_mobility <- function(x, ...) {
  class(x) <- setdiff(class(x), "grd_rank_mobility")
  as.data.frame(x, ...)
}
