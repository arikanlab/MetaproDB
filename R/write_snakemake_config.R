#' Write a Snakemake config file for database building
#'
#' @param build_plan_path Path to build plan TSV.
#' @param final_database Path to final output FASTA.
#' @param resources_dir Directory containing genome zip resources.
#' @param path Output YAML path.
#' @param host_proteome Optional path to a host protein FASTA file.
#'
#' @return Invisibly returns `path`.
#' @export
write_snakemake_config <- function(build_plan_path,
                                   final_database,
                                   resources_dir,
                                   path,
                                   host_proteome = NULL) {
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

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  cfg <- list(
    build_plan = build_plan_path,
    resources_dir = resources_dir,
    final_database = final_database,
    host_proteome = host_proteome
  )

  yaml::write_yaml(cfg, file = path)

  invisible(path)
}