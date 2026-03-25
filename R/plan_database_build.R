#' Plan database build for a selected biome/genera set
#'
#' Creates a workflow-ready build table linking selected genera to genome resource
#' archives and planned output locations.
#'
#' @param manifest_tbl Output of `build_genus_manifest()`.
#' @param genus_index_tbl Output of `read_genus_index()`.
#' @param resource_dir Directory containing genus genome zip files.
#' @param output_root Root output directory for database build products.
#'
#' @return A tibble describing the planned database build.
#' @export
plan_database_build <- function(manifest_tbl,
                                genus_index_tbl,
                                resource_dir,
                                output_root = "results/database_builds") {
  if (!is.data.frame(manifest_tbl)) {
    rlang::abort("`manifest_tbl` must be a data frame.")
  }

  if (!is.data.frame(genus_index_tbl)) {
    rlang::abort("`genus_index_tbl` must be a data frame.")
  }

  if (!dir.exists(resource_dir)) {
    rlang::abort(paste0("Resource directory not found: ", resource_dir))
  }

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

  required_index_cols <- c(
    "genus_file_stub", "zip_filename", "accession_count"
  )
  missing_index <- setdiff(required_index_cols, colnames(genus_index_tbl))
  if (length(missing_index) > 0) {
    rlang::abort(
      paste0(
        "Genus index is missing required columns: ",
        paste(missing_index, collapse = ", ")
      )
    )
  }

  out <- manifest_tbl |>
    dplyr::left_join(
      genus_index_tbl,
      by = "genus_file_stub",
      suffix = c("", "_index")
    ) |>
    dplyr::mutate(
      resource_listed = !is.na(.data$zip_filename),
      zip_path = dplyr::if_else(
        .data$resource_listed,
        file.path(resource_dir, .data$zip_filename),
        NA_character_
      ),
      resource_present = .data$resource_listed & file.exists(.data$zip_path),
      download_required = .data$resource_listed & !.data$resource_present,
      rehydrated_dir = file.path(
        output_root, .data$biome_id, "rehydrated", paste0(.data$genus_file_stub, "_genomes")
      ),
      protein_fasta = file.path(
        output_root, .data$biome_id, "proteins", paste0(.data$genus_file_stub, ".faa")
      ),
      ready_to_build = .data$resource_present
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
      dplyr::any_of(c(
        "resource_version",
        "source_database",
        "snapshot_date",
        "accession_count",
        "checksum",
        "file_size_bytes"
      )),
      rehydrated_dir,
      protein_fasta,
      ready_to_build
    )

  out
}