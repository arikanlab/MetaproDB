test_that("rank_taxa returns expected columns", {
  ps <- load_biome("saliva")
  x <- rank_taxa(ps)

  expect_s3_class(x, "tbl_df")
  expect_equal(
    colnames(x),
    c(
      "rank",
      "taxon",
      "mean_abundance",
      "median_abundance",
      "prevalence",
      "total_relative_abundance"
    )
  )
  expect_true(nrow(x) > 0)
})

test_that("rank_taxa ranks taxa in descending mean abundance", {
  ps <- load_biome("saliva")
  x <- rank_taxa(ps)

  expect_true(all(diff(x$mean_abundance) <= 1e-12))
})

test_that("rank_taxa removes Other by default", {
  ps <- load_biome("saliva")
  x <- rank_taxa(ps)

  expect_false("Other" %in% x$taxon)
})