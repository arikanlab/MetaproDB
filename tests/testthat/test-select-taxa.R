test_that("select_taxa returns expected columns", {
  ps <- load_biome("saliva")
  x <- select_taxa(ps, top_n = 20)

  expect_s3_class(x, "tbl_df")
  expect_true(all(c(
    "rank", "taxon", "mean_abundance", "median_abundance",
    "prevalence", "total_relative_abundance", "source"
  ) %in% colnames(x)))
})

test_that("select_taxa without core returns top_n taxa", {
  ps <- load_biome("saliva")
  x <- select_taxa(ps, top_n = 20, include_core = FALSE)

  expect_equal(nrow(x), 20)
  expect_true(all(x$source == "top_n"))
})

test_that("select_taxa with core includes valid source labels", {
  ps <- load_biome("saliva")
  x <- select_taxa(ps, top_n = 20, include_core = TRUE)

  expect_true(all(x$source %in% c("top_n", "core", "top_n+core")))
})