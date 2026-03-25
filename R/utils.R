# Internal utility: path under inst/extdata
#' @noRd
pkg_extdata <- function(...) {
  system.file("extdata", ..., package = "metaprodb")
}

# Internal utility: required metadata columns
#' @noRd
required_biome_metadata_cols <- function() {
  c(
    "biome_id",
    "biome_name",
    "object_file",
    "resource_version",
    "source_database",
    "selection_criteria",
    "pipeline_min_version",
    "n_samples",
    "n_taxa",
    "tax_rank",
    "assay_type",
    "normalization",
    "preprocessing_notes",
    "genome_resource_set",
    "default_top_n",
    "default_core_prevalence",
    "default_core_abundance",
    "notes"
  )
}

# Internal utility: basic phyloseq validation
#' @noRd
validate_phyloseq <- function(ps) {
  if (!inherits(ps, "phyloseq")) {
    rlang::abort("Object is not a phyloseq object.")
  }
  invisible(TRUE)
}