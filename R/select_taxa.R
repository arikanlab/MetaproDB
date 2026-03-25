#' Select taxa for database construction
#'
#' Combines top-N ranked taxa with optional core taxa at a target taxonomic rank.
#'
#' @param ps A phyloseq object.
#' @param rank Taxonomic rank to aggregate on. Default is `"Genus"`.
#' @param top_n Number of highest-ranked taxa to retain.
#' @param include_core Logical; if `TRUE`, union top-N taxa with core taxa.
#' @param prevalence Minimum prevalence threshold for core taxa.
#' @param abundance Minimum mean relative abundance threshold for core taxa.
#' @param keep_unclassified Logical; if `FALSE`, remove uninformative taxon labels.
#'
#' @return A tibble of selected taxa with source annotation.
#' @export
select_taxa <- function(ps,
                        rank = "Genus",
                        top_n = 50,
                        include_core = TRUE,
                        prevalence = 0.5,
                        abundance = 0.01,
                        keep_unclassified = FALSE) {
  validate_phyloseq(ps)

  if (!is.numeric(top_n) || length(top_n) != 1 || is.na(top_n) || top_n < 1) {
    rlang::abort("`top_n` must be a single positive number.")
  }

  top_tbl <- rank_taxa(
    ps,
    rank = rank,
    keep_unclassified = keep_unclassified
  ) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(source = "top_n")

  if (!isTRUE(include_core)) {
    return(top_tbl)
  }

  core_tbl <- define_core_taxa(
    ps,
    rank = rank,
    prevalence = prevalence,
    abundance = abundance,
    keep_unclassified = keep_unclassified
  ) |>
    dplyr::mutate(source = "core")

  out <- dplyr::bind_rows(top_tbl, core_tbl) |>
    dplyr::group_by(.data$taxon) |>
    dplyr::summarise(
      mean_abundance = max(.data$mean_abundance),
      median_abundance = max(.data$median_abundance),
      prevalence = max(.data$prevalence),
      total_relative_abundance = max(.data$total_relative_abundance),
      source = dplyr::case_when(
        all(c("top_n", "core") %in% .data$source) ~ "top_n+core",
        "top_n" %in% .data$source ~ "top_n",
        "core" %in% .data$source ~ "core",
        TRUE ~ NA_character_
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(.data$mean_abundance), .data$taxon) |>
    dplyr::mutate(rank = dplyr::row_number()) |>
    dplyr::relocate(rank, .before = taxon)

  out
}