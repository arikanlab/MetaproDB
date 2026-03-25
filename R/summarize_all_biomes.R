#' Summarize all curated biomes
#'
#' Runs `summarize_biome()` on all bundled biomes.
#'
#' @return A tibble with one row per biome.
#' @export
summarize_all_biomes <- function() {
  dplyr::bind_rows(lapply(list_biomes(), summarize_biome))
}