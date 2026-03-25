#' Write build provenance for a completed database build
#'
#' @param build_plan Path to build plan TSV or a build plan data frame.
#' @param final_database Path to final FASTA database.
#' @param final_manifest Optional path to final manifest TSV. If NULL, inferred
#'   from `final_database`.
#' @param output_path Output TSV path for provenance metadata.
#' @param host_proteome Optional host proteome path.
#' @param resource_mode Optional resource mode description, e.g. `"cache"` or `"fresh"`.
#' @param genus_index_used Optional path to genus index used for planning.
#'
#' @return Invisibly returns `output_path`.
#' @export
write_build_provenance <- function(build_plan,
                                   final_database,
                                   final_manifest = NULL,
                                   output_path,
                                   host_proteome = NULL,
                                   resource_mode = NA_character_,
                                   genus_index_used = NA_character_) {
  if (is.character(build_plan) && length(build_plan) == 1) {
    build_plan_path <- build_plan
    build_plan_tbl <- readr::read_tsv(build_plan, show_col_types = FALSE)
  } else if (is.data.frame(build_plan)) {
    build_plan_path <- NA_character_
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

  if (!is.character(output_path) || length(output_path) != 1 || is.na(output_path)) {
    rlang::abort("`output_path` must be a single non-missing character value.")
  }

  sha256_file <- function(path) {
    if (!file.exists(path)) {
      return(NA_character_)
    }

    sys <- Sys.info()[["sysname"]]

    if (identical(sys, "Darwin")) {
      out <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = FALSE))
      if (length(out) == 0) return(NA_character_)
      return(strsplit(out[[1]], "\\s+")[[1]][1])
    }

    out <- suppressWarnings(system2("sha256sum", path, stdout = TRUE, stderr = FALSE))
    if (length(out) == 0) return(NA_character_)
    strsplit(out[[1]], "\\s+")[[1]][1]
  }

  qc <- summarize_database_build(
    build_plan = build_plan_tbl,
    final_database = final_database,
    final_manifest = final_manifest
  )

  provenance_tbl <- tibble::tibble(
    biome_id = if ("biome_id" %in% colnames(build_plan_tbl)) unique(build_plan_tbl$biome_id)[1] else NA_character_,
    build_date = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    build_plan_path = build_plan_path,
    final_database = final_database,
    final_manifest = final_manifest,
    host_proteome = if (is.null(host_proteome)) NA_character_ else host_proteome,
    resource_mode = resource_mode,
    genus_index_used = genus_index_used,
    n_selected_genera = qc$summary$n_selected_genera,
    n_protein_fastas_found = qc$summary$n_protein_fastas_found,
    pre_dedup_sequences = qc$summary$pre_dedup_sequences,
    post_dedup_sequences = qc$summary$post_dedup_sequences,
    deduplicated_sequences_removed = qc$summary$deduplicated_sequences_removed,
    deduplication_percent = qc$summary$deduplication_percent,
    final_database_size_bytes = qc$summary$final_database_size_bytes,
    final_manifest_size_bytes = qc$summary$final_manifest_size_bytes,
    final_database_sha256 = sha256_file(final_database),
    final_manifest_sha256 = sha256_file(final_manifest)
  )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_tsv(provenance_tbl, output_path)

  invisible(output_path)
}

