#' Build a genus manifest for downstream database construction
#'
#' Converts a selected-taxa table into a workflow-ready manifest for genome
#' resource lookup and database assembly.
#'
#' @param taxa_tbl Output of `select_taxa()` or a compatible tibble containing
#'   at least a `taxon` column.
#' @param biome_id Biome identifier.
#'
#' @return A tibble manifest for downstream workflow execution.
#' @export
build_genus_manifest <- function(taxa_tbl, biome_id) {
  if (!is.data.frame(taxa_tbl)) {
    rlang::abort("`taxa_tbl` must be a data frame or tibble.")
  }

  if (!"taxon" %in% colnames(taxa_tbl)) {
    rlang::abort("`taxa_tbl` must contain a `taxon` column.")
  }

  if (!is.character(biome_id) || length(biome_id) != 1 || is.na(biome_id)) {
    rlang::abort("`biome_id` must be a single non-missing character value.")
  }

  out <- tibble::tibble(
    biome_id = biome_id,
    genus = taxa_tbl$taxon,
    genus_file_stub = gsub("[^A-Za-z0-9._-]+", "_", taxa_tbl$taxon),
    selection_source = if ("source" %in% colnames(taxa_tbl)) taxa_tbl$source else NA_character_,
    mean_abundance = if ("mean_abundance" %in% colnames(taxa_tbl)) taxa_tbl$mean_abundance else NA_real_,
    median_abundance = if ("median_abundance" %in% colnames(taxa_tbl)) taxa_tbl$median_abundance else NA_real_,
    prevalence = if ("prevalence" %in% colnames(taxa_tbl)) taxa_tbl$prevalence else NA_real_,
    total_relative_abundance = if ("total_relative_abundance" %in% colnames(taxa_tbl)) taxa_tbl$total_relative_abundance else NA_real_
  )

  out
}

#' Write a genus manifest to TSV
#'
#' @param manifest_tbl Manifest table produced by `build_genus_manifest()`.
#' @param path Output file path.
#'
#' @return Invisibly returns `path`.
#' @export
write_manifest_tsv <- function(manifest_tbl, path) {
  if (!is.data.frame(manifest_tbl)) {
    rlang::abort("`manifest_tbl` must be a data frame or tibble.")
  }

  readr::write_tsv(manifest_tbl, path)
  invisible(path)
}