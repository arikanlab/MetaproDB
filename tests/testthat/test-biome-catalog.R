test_that("biome_metadata returns required columns", {
  meta <- biome_metadata()
  expect_s3_class(meta, "tbl_df")

  req <- c(
    "biome_id", "biome_name", "object_file", "n_samples", "n_taxa", "tax_rank"
  )
  expect_true(all(req %in% colnames(meta)))
})

test_that("list_biomes returns character vector", {
  x <- list_biomes()
  expect_type(x, "character")
  expect_true(length(x) > 0)
})

test_that("get_biome_info returns one row", {
  ids <- list_biomes()
  info <- get_biome_info(ids[[1]])
  expect_s3_class(info, "tbl_df")
  expect_equal(nrow(info), 1)
})

test_that("load_biome loads a phyloseq object", {
  ids <- list_biomes()
  ps <- load_biome(ids[[1]])
  expect_true(inherits(ps, "phyloseq"))
})

devtools::load_all()
