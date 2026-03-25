#' Read curated biome metadata
#'
#' @return A tibble with one row per curated biome.
#' @export
biome_metadata <- function() {
  path <- pkg_extdata("biome_metadata.tsv")

  if (!nzchar(path) || !file.exists(path)) {
    rlang::abort("Could not find inst/extdata/biome_metadata.tsv.")
  }

  meta <- readr::read_tsv(path, show_col_types = FALSE)

  missing_cols <- setdiff(required_biome_metadata_cols(), names(meta))
  if (length(missing_cols) > 0) {
    rlang::abort(
      paste0(
        "Biome metadata is missing required columns: ",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  if (anyDuplicated(meta$biome_id)) {
    dup_ids <- unique(meta$biome_id[duplicated(meta$biome_id)])
    rlang::abort(
      paste0("Duplicate biome_id values found: ", paste(dup_ids, collapse = ", "))
    )
  }

  meta
}

#' List curated biome IDs
#'
#' @return Character vector of biome IDs.
#' @export
list_biomes <- function() {
  biome_metadata()$biome_id
}

#' Get metadata for one curated biome
#'
#' @param biome_id A biome ID from `list_biomes()`.
#'
#' @return A one-row tibble with metadata for the requested biome.
#' @export
get_biome_info <- function(biome_id) {
  if (!is.character(biome_id) || length(biome_id) != 1 || is.na(biome_id)) {
    rlang::abort("`biome_id` must be a single non-missing character value.")
  }

  meta <- biome_metadata()
  row <- meta[meta$biome_id == biome_id, , drop = FALSE]

  if (nrow(row) == 0) {
    rlang::abort(
      paste0(
        "Unknown biome_id: `", biome_id,
        "`. Use `list_biomes()` to inspect available biomes."
      )
    )
  }

  row
}