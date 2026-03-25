#' Plan a database build from a bundled biome
#'
#' Loads a curated bundled biome, selects taxa, builds a genus manifest,
#' and creates a database build plan.
#'
#' @param biome_id A bundled biome ID from `list_biomes()`.
#' @param genus_index_tbl Output of `read_genus_index()`.
#' @param resource_dir Directory containing genus genome zip files.
#' @param output_root Root output directory for build products.
#' @param rank Taxonomic rank for selection. Default is `"Genus"`.
#' @param top_n Number of highest-ranked taxa to keep.
#' @param include_core Logical; if `TRUE`, union top-N taxa with core taxa.
#' @param prevalence Minimum prevalence threshold for core taxa.
#' @param abundance Minimum mean relative abundance threshold for core taxa.
#' @param keep_unclassified Logical; if `FALSE`, remove uninformative taxon labels.
#' @param write_plan Logical; if `TRUE`, write the build plan TSV to disk.
#'
#' @return A named list with elements:
#'   \describe{
#'     \item{biome_info}{One-row tibble of bundled biome metadata}
#'     \item{summary}{One-row tibble summarizing the loaded biome}
#'     \item{selected}{Selected taxa table}
#'     \item{manifest}{Genus manifest}
#'     \item{build_plan}{Workflow-ready build plan}
#'     \item{build_plan_path}{Output path for the build plan TSV}
#'   }
#' @export
plan_build_from_biome <- function(biome_id,
                                  genus_index_tbl,
                                  resource_dir,
                                  output_root = "results/database_builds",
                                  rank = "Genus",
                                  top_n = 20,
                                  include_core = TRUE,
                                  prevalence = 0.5,
                                  abundance = 0.01,
                                  keep_unclassified = FALSE,
                                  write_plan = TRUE) {
  if (!is.character(biome_id) || length(biome_id) != 1 || is.na(biome_id)) {
    rlang::abort("`biome_id` must be a single non-missing character value.")
  }

  if (!is.data.frame(genus_index_tbl)) {
    rlang::abort("`genus_index_tbl` must be a data frame.")
  }

  if (!dir.exists(resource_dir)) {
    rlang::abort(paste0("Resource directory not found: ", resource_dir))
  }

  biome_info <- get_biome_info(biome_id)
  ps <- load_biome(biome_id)

  summary_tbl <- summarize_biome(biome_id)

  selected_tbl <- select_taxa(
    ps = ps,
    rank = rank,
    top_n = top_n,
    include_core = include_core,
    prevalence = prevalence,
    abundance = abundance,
    keep_unclassified = keep_unclassified
  )

  manifest_tbl <- build_genus_manifest(
    taxa_tbl = selected_tbl,
    biome_id = biome_id
  )

  build_plan_tbl <- plan_database_build(
    manifest_tbl = manifest_tbl,
    genus_index_tbl = genus_index_tbl,
    resource_dir = resource_dir,
    output_root = output_root
  )

  build_plan_path <- file.path(
    output_root,
    biome_id,
    paste0(biome_id, "_build_plan.tsv")
  )

  config_path <- file.path(
    output_root,
    biome_id,
    paste0(biome_id, "_snakemake_config.yml")
  )

  final_database_path <- file.path(
    output_root,
    biome_id,
    paste0("MetaproDB_", biome_id, ".faa")
  )

  if (isTRUE(write_plan)) {
    write_snakemake_config(
      build_plan_path = build_plan_path,
      final_database = final_database_path,
      resources_dir = resource_dir,
      path = config_path
    )
    write_build_plan_tsv(
      build_plan_tbl,
      build_plan_path
    )
  }

  list(
    biome_info = biome_info,
    summary = summary_tbl,
    selected = selected_tbl,
    manifest = manifest_tbl,
    build_plan = build_plan_tbl,
    build_plan_path = build_plan_path,
    config_path = config_path,
    final_database_path = final_database_path
  )
}