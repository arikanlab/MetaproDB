#' Write a Snakemake config file for database building
#'
#' @param build_plan_path Path to build plan TSV.
#' @param final_database Path to final output FASTA.
#' @param resources_dir Directory containing genome zip resources.
#' @param path Output YAML path.
#' @param host_proteome Optional path to a host protein FASTA file.
#' @param download_failure_policy How to handle partial download/rehydration failures.
#'   Must be either `"permissive"` or `"strict"`.
#' @param min_genome_success_fraction Minimum fraction of expected genomes that
#'   must be successfully recovered for the build to continue in permissive mode.
#'   Must be between 0 and 1.
#' @param min_genus_success_fraction Minimum fraction of selected genera that
#'   must be represented by at least one recovered protein FASTA for the build
#'   to continue in permissive mode. Must be between 0 and 1.
#'
#' @return Invisibly returns `path`.
#' @export
write_snakemake_config <- function(build_plan_path,
                                   final_database,
                                   resources_dir,
                                   path,
                                   host_proteome = NULL,
                                   download_failure_policy = "permissive",
                                   min_genome_success_fraction = 0.8,
                                   min_genus_success_fraction = 0.8) {
  if (!is.character(build_plan_path) || length(build_plan_path) != 1 || is.na(build_plan_path)) {
    rlang::abort("`build_plan_path` must be a single non-missing character value.")
  }

  if (!is.character(final_database) || length(final_database) != 1 || is.na(final_database)) {
    rlang::abort("`final_database` must be a single non-missing character value.")
  }

  if (!is.character(resources_dir) || length(resources_dir) != 1 || is.na(resources_dir)) {
    rlang::abort("`resources_dir` must be a single non-missing character value.")
  }

  if (!is.character(path) || length(path) != 1 || is.na(path)) {
    rlang::abort("`path` must be a single non-missing character value.")
  }

  if (!is.null(host_proteome)) {
    if (!is.character(host_proteome) || length(host_proteome) != 1 || is.na(host_proteome)) {
      rlang::abort("`host_proteome` must be NULL or a single non-missing character value.")
    }
  }

  if (!is.character(download_failure_policy) ||
      length(download_failure_policy) != 1 ||
      is.na(download_failure_policy) ||
      !download_failure_policy %in% c("permissive", "strict")) {
    rlang::abort(
      "`download_failure_policy` must be a single character value: 'permissive' or 'strict'."
    )
  }

  if (!is.numeric(min_genome_success_fraction) ||
      length(min_genome_success_fraction) != 1 ||
      is.na(min_genome_success_fraction) ||
      min_genome_success_fraction < 0 ||
      min_genome_success_fraction > 1) {
    rlang::abort(
      "`min_genome_success_fraction` must be a single numeric value between 0 and 1."
    )
  }

  if (!is.numeric(min_genus_success_fraction) ||
      length(min_genus_success_fraction) != 1 ||
      is.na(min_genus_success_fraction) ||
      min_genus_success_fraction < 0 ||
      min_genus_success_fraction > 1) {
    rlang::abort(
      "`min_genus_success_fraction` must be a single numeric value between 0 and 1."
    )
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  cfg <- list(
    build_plan = build_plan_path,
    resources_dir = resources_dir,
    final_database = final_database,
    host_proteome = host_proteome,
    download_failure_policy = download_failure_policy,
    min_genome_success_fraction = min_genome_success_fraction,
    min_genus_success_fraction = min_genus_success_fraction
  )

  yaml::write_yaml(cfg, file = path)

  invisible(path)
}