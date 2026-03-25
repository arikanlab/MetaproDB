#' Rank taxa by abundance at a target taxonomic level
#'
#' Converts a phyloseq object to compositional abundance, aggregates features to a
#' requested taxonomic rank, and ranks taxa by mean relative abundance across samples.
#'
#' The default behavior mirrors the logic used in MetaproDB top-genus selection:
#' taxa are aggregated to genus level, and uninformative labels such as `Other`,
#' `unclassified`, `uncultured`, `unknown`, and `metagenome` are excluded.
#'
#' @param ps A phyloseq object.
#' @param rank Taxonomic rank to aggregate on. Default is `"Genus"`.
#' @param keep_unclassified Logical; if `FALSE`, remove uninformative taxon labels.
#'
#' @return A tibble with ranked taxa and abundance statistics.
#' @export
rank_taxa <- function(ps, rank = "Genus", keep_unclassified = FALSE) {
  validate_phyloseq(ps)

  if (!inherits(ps, "phyloseq")) {
    rlang::abort("`ps` must be a phyloseq object.")
  }

  tt <- as.data.frame(phyloseq::tax_table(ps), stringsAsFactors = FALSE)
  if (!rank %in% colnames(tt)) {
    rlang::abort(paste0("Rank `", rank, "` not found in taxonomy table."))
  }

  # Convert to compositional abundance
  ps_comp <- microbiome::transform(ps, "compositional")

  # Aggregate to requested taxonomic level
  ps_rank <- microbiomeutilities::aggregate_top_taxa2(
    ps_comp,
    top = 50000,
    level = rank
  )

  otu <- as(phyloseq::otu_table(ps_rank), "matrix")
  if (!phyloseq::taxa_are_rows(ps_rank)) {
    otu <- t(otu)
  }

  tax <- as.data.frame(phyloseq::tax_table(ps_rank), stringsAsFactors = FALSE)
  tax_names <- trimws(as.character(tax[[rank]]))

  # Per-taxon summary statistics across samples
  mean_abundance <- rowMeans(otu)
  median_abundance <- apply(otu, 1, stats::median)
  prevalence <- rowMeans(otu > 0)
  total_relative_abundance <- rowSums(otu)

  out <- tibble::tibble(
    taxon = tax_names,
    mean_abundance = as.numeric(mean_abundance),
    median_abundance = as.numeric(median_abundance),
    prevalence = as.numeric(prevalence),
    total_relative_abundance = as.numeric(total_relative_abundance)
  ) |>
    dplyr::filter(!is.na(.data$taxon), .data$taxon != "", .data$taxon != "Other")

  if (!isTRUE(keep_unclassified)) {
    out <- out |>
      dplyr::filter(
        !grepl(
          "^unclassified$|^uncultured$|unclassified|uncultured|unknown|metagenome",
          .data$taxon,
          ignore.case = TRUE
        )
      )
  }

  out |>
    dplyr::arrange(dplyr::desc(.data$mean_abundance), .data$taxon) |>
    dplyr::mutate(rank = dplyr::row_number()) |>
    dplyr::relocate(rank, .before = taxon)
}