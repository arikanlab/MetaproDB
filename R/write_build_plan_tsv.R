#' Write a database build plan to TSV
#'
#' @param build_plan_tbl Output of `plan_database_build()`.
#' @param path Output TSV path.
#'
#' @return Invisibly returns `path`.
#' @export
write_build_plan_tsv <- function(build_plan_tbl, path) {

  if (!is.data.frame(build_plan_tbl)) {
    rlang::abort("`build_plan_tbl` must be a data frame.")
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  readr::write_tsv(build_plan_tbl, path)

  invisible(path)
}