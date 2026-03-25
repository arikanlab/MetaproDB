#' Validate genus manifest against genome resource catalog
#'
#' Checks whether genera selected for a biome have matching genome resources.
#'
#' @param manifest_tbl Output of `build_genus_manifest()`.
#' @param genus_index_tbl Output of `read_genus_index()`.
#' @param resource_dir Directory containing dehydrated genome zip files.
#'
#' @return A tibble with validation results.
#' @export
validate_genus_manifest <- function(
  manifest_tbl,
  genus_index_tbl,
  resource_dir
) {

  if (!is.data.frame(manifest_tbl)) {
    rlang::abort("`manifest_tbl` must be a data frame.")
  }

  if (!is.data.frame(genus_index_tbl)) {
    rlang::abort("`genus_index_tbl` must be a data frame.")
  }

  if (!dir.exists(resource_dir)) {
    rlang::abort(paste0("Resource directory not found: ", resource_dir))
  }

  merged <- manifest_tbl |>
    dplyr::left_join(
      genus_index_tbl,
      by = c("genus_file_stub" = "genus_file_stub")
    )

  merged <- merged |>
    dplyr::mutate(
      in_resource_index = !is.na(.data$zip_filename),
      zip_path = file.path(resource_dir, .data$zip_filename),
      file_exists = ifelse(
        .data$in_resource_index,
        file.exists(.data$zip_path),
        FALSE
      )
    )

  merged
}