#' Summarize a database build plan
#'
#' @param build_plan_tbl Output of `plan_database_build()`.
#'
#' @return A one-row tibble summarizing build readiness.
#' @export
summarize_build_plan <- function(build_plan_tbl) {
  if (!is.data.frame(build_plan_tbl)) {
    rlang::abort("`build_plan_tbl` must be a data frame.")
  }

  tibble::tibble(
    n_selected = nrow(build_plan_tbl),
    n_ready_to_build = sum(build_plan_tbl$ready_to_build, na.rm = TRUE),
    n_missing_resources = sum(!build_plan_tbl$ready_to_build, na.rm = TRUE),
    total_accessions = sum(build_plan_tbl$accession_count, na.rm = TRUE)
  )
}