test_that("build_genus_manifest returns expected columns", {
  ps <- load_biome("saliva")
  taxa_tbl <- select_taxa(ps, top_n = 20, include_core = TRUE)
  man <- build_genus_manifest(taxa_tbl, biome_id = "saliva")

  expect_s3_class(man, "tbl_df")
  expect_true(all(c(
    "biome_id", "genus", "genus_file_stub", "selection_source",
    "mean_abundance", "median_abundance", "prevalence",
    "total_relative_abundance"
  ) %in% colnames(man)))
  expect_equal(nrow(man), nrow(taxa_tbl))
})