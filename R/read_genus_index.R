#' Read genus genome resource index
#'
#' @param path Path to genus resource index TSV file.
#'
#' @return A tibble describing available genus genome resources.
#' @export
read_genus_index <- function(path) {

  if (!file.exists(path)) {
    rlang::abort(paste0("Genus index file not found: ", path))
  }

  idx <- readr::read_tsv(path, show_col_types = FALSE)

  required_cols <- c(
    "genus",
    "genus_file_stub",
    "zip_filename"
  )

  missing_cols <- setdiff(required_cols, colnames(idx))
  if (length(missing_cols) > 0) {
    rlang::abort(
      paste0(
        "Genus index missing required columns: ",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  idx
}