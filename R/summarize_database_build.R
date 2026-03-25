#' Summarize a completed database build
#'
#' Creates a post-build QC summary from a build plan, final FASTA, and final
#' manifest file.
#'
#' @param build_plan Path to build plan TSV or a data frame returned by
#'   `plan_database_build()` or `plan_database_build_generic()`.
#' @param final_database Path to the final merged FASTA file.
#' @param final_manifest Optional path to the final merged manifest TSV. If NULL,
#'   it is inferred from `final_database` by replacing `.faa` with `.manifest.tsv`.
#'
#' @return A named list with elements:
#'   \describe{
#'     \item{summary}{One-row tibble with build-level QC metrics}
#'     \item{genus_status}{Per-genus tibble showing expected and observed outputs}
#'     \item{missing_genera}{Character vector of genera missing protein FASTA outputs}
#'   }
#' @export
summarize_database_build <- function(build_plan,
                                     final_database,
                                     final_manifest = NULL) {
  if (is.character(build_plan) && length(build_plan) == 1) {
    build_plan_tbl <- readr::read_tsv(build_plan, show_col_types = FALSE)
  } else if (is.data.frame(build_plan)) {
    build_plan_tbl <- tibble::as_tibble(build_plan)
  } else {
    rlang::abort("`build_plan` must be a path or a data frame.")
  }

  if (!is.character(final_database) || length(final_database) != 1 || is.na(final_database)) {
    rlang::abort("`final_database` must be a single non-missing character value.")
  }

  if (is.null(final_manifest)) {
    final_manifest <- sub("\\.faa$", ".manifest.tsv", final_database)
  }

  count_fasta_sequences <- function(path) {
    if (!file.exists(path)) {
      return(NA_integer_)
    }
    lines <- readLines(path, warn = FALSE)
    sum(startsWith(lines, ">"))
  }

  fasta_exists <- file.exists(final_database)
  manifest_exists <- file.exists(final_manifest)

  final_sequence_count <- count_fasta_sequences(final_database)

  manifest_tbl <- if (manifest_exists) {
    readr::read_tsv(final_manifest, show_col_types = FALSE)
  } else {
    tibble::tibble()
  }

  genus_status_tbl <- build_plan_tbl |>
    dplyr::mutate(
      protein_fasta_exists = file.exists(.data$protein_fasta),
      rehydrated_dir_exists = if ("rehydrated_dir" %in% colnames(build_plan_tbl)) {
        dir.exists(.data$rehydrated_dir)
      } else {
        NA
      },
      protein_fasta_sequences = dplyr::if_else(
        .data$protein_fasta_exists,
        vapply(.data$protein_fasta, count_fasta_sequences, integer(1)),
        NA_integer_
      )
    ) |>
    dplyr::select(
      dplyr::any_of(c(
        "biome_id",
        "genus",
        "genus_file_stub",
        "selection_source",
        "zip_filename",
        "zip_path",
        "resource_listed",
        "resource_present",
        "download_required",
        "rehydrated_dir",
        "protein_fasta"
      )),
      rehydrated_dir_exists,
      protein_fasta_exists,
      protein_fasta_sequences
    )

  missing_genera <- genus_status_tbl |>
    dplyr::filter(!.data$protein_fasta_exists) |>
    dplyr::pull(.data$genus)

  pre_dedup_sequences <- sum(genus_status_tbl$protein_fasta_sequences, na.rm = TRUE)
  deduplicated_sequences_removed <- if (fasta_exists) {
    pre_dedup_sequences - final_sequence_count
  } else {
    NA_integer_
  }

  deduplication_fraction <- if (fasta_exists && pre_dedup_sequences > 0) {
    deduplicated_sequences_removed / pre_dedup_sequences
  } else {
    NA_real_
  }

  summary_tbl <- tibble::tibble(
    biome_id = if ("biome_id" %in% colnames(build_plan_tbl)) unique(build_plan_tbl$biome_id)[1] else NA_character_,
    n_selected_genera = nrow(build_plan_tbl),
    n_protein_fastas_expected = nrow(build_plan_tbl),
    n_protein_fastas_found = sum(genus_status_tbl$protein_fasta_exists, na.rm = TRUE),
    n_rehydrated_dirs_found = sum(genus_status_tbl$rehydrated_dir_exists, na.rm = TRUE),
    final_database_exists = fasta_exists,
    final_manifest_exists = manifest_exists,
    pre_dedup_sequences = pre_dedup_sequences,
    post_dedup_sequences = final_sequence_count,
    deduplicated_sequences_removed = deduplicated_sequences_removed,
    deduplication_fraction = deduplication_fraction,
    deduplication_percent = if (!is.na(deduplication_fraction)) deduplication_fraction * 100 else NA_real_,
    final_manifest_rows = if (manifest_exists) nrow(manifest_tbl) else NA_integer_,
    final_manifest_genera = if (manifest_exists && "genus" %in% colnames(manifest_tbl)) dplyr::n_distinct(manifest_tbl$genus) else NA_integer_,
    final_database_size_bytes = if (fasta_exists) file.info(final_database)$size else NA_real_,
    final_manifest_size_bytes = if (manifest_exists) file.info(final_manifest)$size else NA_real_,
    n_missing_genera = length(missing_genera)
  )

  list(
    summary = summary_tbl,
    genus_status = genus_status_tbl,
    missing_genera = missing_genera
  )
}