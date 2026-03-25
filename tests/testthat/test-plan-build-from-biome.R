test_that("plan_build_from_biome returns expected components", {
  genus_index <- read_genus_index(
    testthat::test_path("../../resources/genus_index.tsv")
  )

  res <- plan_build_from_biome(
    biome_id = "saliva",
    genus_index_tbl = genus_index,
    resource_dir = testthat::test_path("../../resources/genomes"),
    output_root = "results/database_builds",
    top_n = 20,
    include_core = TRUE
  )

  expect_true(all(c(
    "biome_info",
    "summary",
    "selected",
    "manifest",
    "build_plan",
    "build_plan_path",
    "config_path",
    "final_database_path"
  ) %in% names(res)))

  expect_s3_class(res$biome_info, "tbl_df")
  expect_s3_class(res$summary, "tbl_df")
  expect_s3_class(res$selected, "tbl_df")
  expect_s3_class(res$manifest, "tbl_df")
  expect_s3_class(res$build_plan, "tbl_df")
})