test_that("define_core_taxa returns expected columns", {
  ps <- load_biome("saliva")
  x <- define_core_taxa(ps)

  expect_s3_class(x, "tbl_df")
  expect_true(all(c(
    "rank", "taxon", "mean_abundance",
    "median_abundance", "prevalence", "total_relative_abundance"
  ) %in% colnames(x)))
})

test_that("define_core_taxa enforces thresholds", {
  ps <- load_biome("saliva")
  x <- define_core_taxa(ps, prevalence = 0.5, abundance = 0.01)

  expect_true(all(x$prevalence >= 0.5))
  expect_true(all(x$mean_abundance >= 0.01))
})