#' Write database build QC report
#'
#' @param qc_report Output of `summarize_database_build()`.
#' @param output_dir Directory where report files will be written.
#' @param prefix File prefix for report files.
#'
#' @return Invisibly returns `output_dir`.
#' @export
write_build_qc_report <- function(qc_report,
                                  output_dir,
                                  prefix = "build_qc") {
  if (!is.list(qc_report) || !all(c("summary", "genus_status", "missing_genera") %in% names(qc_report))) {
    rlang::abort("`qc_report` must be the output of `summarize_database_build()`.")
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  readr::write_tsv(qc_report$summary, file.path(output_dir, paste0(prefix, ".summary.tsv")))
  readr::write_tsv(qc_report$genus_status, file.path(output_dir, paste0(prefix, ".genus_status.tsv")))

  writeLines(
    qc_report$missing_genera,
    con = file.path(output_dir, paste0(prefix, ".missing_genera.txt"))
  )

  invisible(output_dir)
}