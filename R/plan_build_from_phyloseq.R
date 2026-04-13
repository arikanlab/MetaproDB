#' Plan a database build from a user-provided phyloseq object
#'
#' Uses a user-provided phyloseq object, selects taxa, builds a genus manifest,
#' and creates a database build plan.
#'
#' @param ps A phyloseq object provided by the user.
#' @param biome_id Identifier for the custom biome (used for output paths).
#' @param resource_dir Directory containing genus genome zip files, or a
#'   dedicated directory where genome zip files will be downloaded for the
#'   current build.
#' @param output_root Root output directory for build products.
#' @param rank Taxonomic rank for selection. Default is `"Genus"`.
#' @param top_n Number of highest-ranked taxa to keep.
#' @param include_core Logical; if `TRUE`, union top-N taxa with core taxa.
#' @param prevalence Minimum prevalence threshold for core taxa.
#' @param abundance Minimum mean relative abundance threshold for core taxa.
#' @param keep_unclassified Logical; if `FALSE`, remove uninformative taxon labels.
#' @param write_plan Logical; if `TRUE`, write the build plan TSV to disk.
#' @param download_failure_policy How to handle partial download/rehydration
#'   failures in the workflow config. Must be either `"permissive"` or `"strict"`.
#' @param min_genome_success_fraction Minimum fraction of expected genomes that
#'   must be successfully recovered for the build to continue in permissive mode.
#'   Must be between 0 and 1.
#' @param min_genus_success_fraction Minimum fraction of selected genera that
#'   must be represented by at least one recovered protein FASTA for the build
#'   to continue in permissive mode. Must be between 0 and 1.
#'
#' @return A named list with elements:
#'   \describe{
#'     \item{selected}{Selected taxa table}
#'     \item{manifest}{Genus manifest}
#'     \item{build_plan}{Workflow-ready build plan}
#'     \item{build_plan_path}{Output path for the build plan TSV}
#'     \item{config_path}{Output path for the Snakemake config YAML}
#'     \item{final_database_path}{Planned output path for the final FASTA}
#'   }
#' @export
plan_build_from_phyloseq <- function(ps,
                                     biome_id,
                                     resource_dir,
                                     output_root = "results/database_builds",
                                     rank = "Genus",
                                     top_n = 50,
                                     include_core = TRUE,
                                     prevalence = 0.5,
                                     abundance = 0.01,
                                     keep_unclassified = FALSE,
                                     write_plan = TRUE,
                                     download_failure_policy = "permissive",
                                     min_genome_success_fraction = 0.80,
                                     min_genus_success_fraction = 0.80) {

  if (!inherits(ps, "phyloseq")) {
    rlang::abort("`ps` must be a phyloseq object.")
  }

  if (!is.character(biome_id) || length(biome_id) != 1 || is.na(biome_id)) {
    rlang::abort("`biome_id` must be a single non-missing character value.")
  }

  if (!dir.exists(resource_dir)) {
    dir.create(resource_dir, recursive = TRUE, showWarnings = FALSE)
  }

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

  build_plan_tbl <- plan_database_build_generic(
    manifest_tbl = manifest_tbl,
    resource_dir = resource_dir,
    output_root = output_root,
    resource_mode = "fresh"
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
    dir.create(file.path(output_root, biome_id), recursive = TRUE, showWarnings = FALSE)

    write_snakemake_config(
      build_plan_path = build_plan_path,
      final_database = final_database_path,
      resources_dir = resource_dir,
      path = config_path,
      download_failure_policy = download_failure_policy,
      min_genome_success_fraction = min_genome_success_fraction,
      min_genus_success_fraction = min_genus_success_fraction
    )

    write_build_plan_tsv(
      build_plan_tbl,
      build_plan_path
    )
  }

  list(
    selected = selected_tbl,
    manifest = manifest_tbl,
    build_plan = build_plan_tbl,
    build_plan_path = build_plan_path,
    config_path = config_path,
    final_database_path = final_database_path
  )
}