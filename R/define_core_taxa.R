#' Define core taxa at a target taxonomic rank
#'
#' Converts a phyloseq object to compositional abundance, aggregates features to a
#' requested taxonomic rank, and retains taxa passing user-defined prevalence and
#' mean abundance thresholds.
#'
#' The default behavior mirrors MetaproDB genus-level core taxon selection.
#'
#' @param ps A phyloseq object.
#' @param rank Taxonomic rank to aggregate on. Default is `"Genus"`.
#' @param prevalence Minimum fraction of samples in which a taxon must be present.
#' @param abundance Minimum mean relative abundance across samples.
#' @param keep_unclassified Logical; if `FALSE`, remove uninformative taxon labels.
#'
#' @return A tibble of core taxa with abundance statistics.
#' @export
define_core_taxa <- function(ps,
                             rank = "Genus",
                             prevalence = 0.5,
                             abundance = 0.01,
                             keep_unclassified = FALSE) {
  validate_phyloseq(ps)

  if (!inherits(ps, "phyloseq")) {
    rlang::abort("`ps` must be a phyloseq object.")
  }

  if (!is.numeric(prevalence) || length(prevalence) != 1 || is.na(prevalence) ||
      prevalence < 0 || prevalence > 1) {
    rlang::abort("`prevalence` must be a single numeric value between 0 and 1.")
  }

  if (!is.numeric(abundance) || length(abundance) != 1 || is.na(abundance) ||
      abundance < 0 || abundance > 1) {
    rlang::abort("`abundance` must be a single numeric value between 0 and 1.")
  }

  tt <- as.data.frame(phyloseq::tax_table(ps), stringsAsFactors = FALSE)
  if (!rank %in% colnames(tt)) {
    rlang::abort(paste0("Rank `", rank, "` not found in taxonomy table."))
  }

  ps_comp <- microbiome::transform(ps, "compositional")

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

  out <- tibble::tibble(
    taxon = tax_names,
    mean_abundance = as.numeric(rowMeans(otu)),
    median_abundance = as.numeric(apply(otu, 1, stats::median)),
    prevalence = as.numeric(rowMeans(otu > 0)),
    total_relative_abundance = as.numeric(rowSums(otu))
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
    dplyr::filter(
      .data$prevalence >= prevalence,
      .data$mean_abundance >= abundance
    ) |>
    dplyr::arrange(dplyr::desc(.data$mean_abundance), .data$taxon) |>
    dplyr::mutate(rank = dplyr::row_number()) |>
    dplyr::relocate(rank, .before = taxon)
}