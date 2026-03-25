#' Load a curated biome phyloseq object
#'
#' @param biome_id A biome ID from `list_biomes()`.
#'
#' @return A phyloseq object.
#' @export
load_biome <- function(biome_id) {
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

  object_file <- row$object_file[1]
  path <- pkg_extdata("biomes", object_file)

  if (!nzchar(path) || !file.exists(path)) {
    rlang::abort(
      paste0(
        "Biome object file not found for `", biome_id,
        "`: inst/extdata/biomes/", object_file
      )
    )
  }

  ps <- readRDS(path)
  validate_phyloseq(ps)
  ps
}