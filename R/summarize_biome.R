#' Summarize a curated biome or phyloseq object
#'
#' @param x A phyloseq object or a single biome ID.
#' @param biome_id Optional biome ID to attach metadata when `x` is a phyloseq object.
#'
#' @return A one-row tibble with summary statistics.
#' @export
summarize_biome <- function(x, biome_id = NULL) {
  if (inherits(x, "phyloseq")) {
    ps <- x

    if (!is.null(biome_id)) {
      info <- get_biome_info(biome_id)
      biome_id_out <- info$biome_id[[1]]
      biome_name <- info$biome_name[[1]]
      tax_rank <- info$tax_rank[[1]]
      selection_rank <- if ("selection_rank" %in% colnames(info)) info$selection_rank[[1]] else NA_character_
    } else {
      biome_id_out <- NA_character_
      biome_name <- NA_character_
      tax_rank <- NA_character_
      selection_rank <- NA_character_
    }

  } else if (is.character(x) && length(x) == 1 && !is.na(x)) {
    info <- get_biome_info(x)
    ps <- load_biome(x)
    biome_id_out <- info$biome_id[[1]]
    biome_name <- info$biome_name[[1]]
    tax_rank <- info$tax_rank[[1]]
    selection_rank <- if ("selection_rank" %in% colnames(info)) info$selection_rank[[1]] else NA_character_
  } else {
    rlang::abort("`x` must be either a phyloseq object or a single biome ID.")
  }

  validate_phyloseq(ps)

  otu <- as(phyloseq::otu_table(ps), "matrix")
  if (!phyloseq::taxa_are_rows(ps)) {
    otu <- t(otu)
  }

  sample_depths <- colSums(otu)
  tt <- as.data.frame(phyloseq::tax_table(ps), stringsAsFactors = FALSE)

  count_non_missing_unique <- function(v) {
    v <- trimws(as.character(v))
    v <- v[!is.na(v) & nzchar(v)]
    length(unique(v))
  }

  n_phyla <- if ("Phylum" %in% colnames(tt)) count_non_missing_unique(tt$Phylum) else NA_integer_
  n_families <- if ("Family" %in% colnames(tt)) count_non_missing_unique(tt$Family) else NA_integer_
  n_genera <- if ("Genus" %in% colnames(tt)) count_non_missing_unique(tt$Genus) else NA_integer_

  tibble::tibble(
    biome_id = biome_id_out,
    biome_name = biome_name,
    n_samples = phyloseq::nsamples(ps),
    n_otus = phyloseq::ntaxa(ps),
    total_reads = sum(sample_depths),
    mean_reads_per_sample = mean(sample_depths),
    median_reads_per_sample = stats::median(sample_depths),
    min_reads_per_sample = min(sample_depths),
    max_reads_per_sample = max(sample_depths),
    n_phyla = n_phyla,
    n_families = n_families,
    n_genera = n_genera,
    tax_rank = tax_rank,
    selection_rank = selection_rank
  )
}