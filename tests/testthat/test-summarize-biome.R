test_that("summarize_biome works with biome ID", {
  x <- summarize_biome("saliva")
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 1)
  expect_true(all(c("n_samples", "n_otus", "n_genera") %in% colnames(x)))
})

test_that("summarize_biome works with phyloseq object", {
  ps <- load_biome("saliva")
  x <- summarize_biome(ps)
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 1)
})