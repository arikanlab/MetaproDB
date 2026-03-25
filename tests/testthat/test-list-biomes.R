test_that("list_biomes returns a character vector", {
  x <- list_biomes()
  expect_type(x, "character")
})
