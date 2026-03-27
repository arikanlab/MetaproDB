#' Plan a generic database build without a genome resource index
#'
#' Creates a workflow-ready build table from a genus manifest by constructing
#' expected genome zip paths and downstream output paths. This planner does not
#' require a pre-existing genus index and is intended for workflows where
#' Snakemake either uses only existing local archives (`"cache"`) or downloads
#' fresh genome archives for all selected genera (`"fresh"`).
#'
#' @param manifest_tbl Output of `build_genus_manifest()`.
#' @param resource_dir Directory containing genus genome zip files, or a
#'   dedicated directory where genome zip files will be downloaded for the
#'   current build.
#' @param output_root Root output directory for database build products.
#' @param resource_mode Resource handling mode. `"cache"` uses only existing local
#'   genome zip files and does not trigger downloads. `"fresh"` marks all genera
#'   for fresh download regardless of existing local files.
#'
#' @return A tibble describing the planned generic database build.
#' @export
plan_database_build_generic <- function(manifest_tbl,
                                        resource_dir,
                                        output_root = "results/database_builds",
                                        resource_mode = c("cache", "fresh")) {
  if (!is.data.frame(manifest_tbl)) {
    rlang::abort("`manifest_tbl` must be a data frame.")
  }

  if (!is.character(resource_dir) || length(resource_dir) != 1 || is.na(resource_dir)) {
    rlang::abort("`resource_dir` must be a single non-missing character value.")
  }

  if (!dir.exists(resource_dir)) {
    dir.create(resource_dir, recursive = TRUE, showWarnings = FALSE)
  }

  resource_mode <- match.arg(resource_mode)

  required_manifest_cols <- c(
    "biome_id", "genus", "genus_file_stub", "selection_source"
  )
  missing_manifest <- setdiff(required_manifest_cols, colnames(manifest_tbl))
  if (length(missing_manifest) > 0) {
    rlang::abort(
      paste0(
        "Manifest is missing required columns: ",
        paste(missing_manifest, collapse = ", ")
      )
    )
  }

  out <- manifest_tbl |>
    dplyr::mutate(
      zip_filename = paste0(.data$genus_file_stub, "_genomes.zip"),
      zip_path = file.path(resource_dir, .data$zip_filename),
      resource_listed = TRUE,
      resource_present = file.exists(.data$zip_path),
      download_required = dplyr::case_when(
        resource_mode == "fresh" ~ TRUE,
        resource_mode == "cache" ~ FALSE
      ),
      rehydrated_dir = file.path(
        output_root, .data$biome_id, "rehydrated", paste0(.data$genus_file_stub, "_genomes")
      ),
      protein_fasta = file.path(
        output_root, .data$biome_id, "proteins", paste0(.data$genus_file_stub, ".faa")
      ),
      ready_to_build = dplyr::case_when(
        resource_mode == "fresh" ~ TRUE,
        resource_mode == "cache" ~ .data$resource_present
      )
    ) |>
    dplyr::select(
      biome_id,
      genus,
      genus_file_stub,
      selection_source,
      dplyr::any_of(c(
        "mean_abundance",
        "median_abundance",
        "prevalence",
        "total_relative_abundance"
      )),
      zip_filename,
      zip_path,
      resource_listed,
      resource_present,
      download_required,
      rehydrated_dir,
      protein_fasta,
      ready_to_build
    )

  out
}