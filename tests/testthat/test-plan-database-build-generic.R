test_that("plan_database_build_generic handles cache mode with present resource", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  resource_dir <- file.path(tmpdir, "genomes")
  dir.create(resource_dir, recursive = TRUE)

  zip_name <- "Testgenus_genomes.zip"
  zip_path <- file.path(resource_dir, zip_name)
  writeLines("dummy zip content", zip_path)

  manifest_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Testgenus",
    genus_file_stub = "Testgenus",
    selection_source = "top_n"
  )

  res <- plan_database_build_generic(
    manifest_tbl = manifest_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds"),
    resource_mode = "cache"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_true(res$resource_listed[[1]])
  expect_true(res$resource_present[[1]])
  expect_false(res$download_required[[1]])
  expect_true(res$ready_to_build[[1]])

  expect_equal(res$zip_filename[[1]], zip_name)
  expect_equal(res$zip_path[[1]], zip_path)
})

test_that("plan_database_build_generic handles cache mode with missing resource", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  resource_dir <- file.path(tmpdir, "genomes")
  dir.create(resource_dir, recursive = TRUE)

  manifest_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Missinggenus",
    genus_file_stub = "Missinggenus",
    selection_source = "top_n"
  )

  res <- plan_database_build_generic(
    manifest_tbl = manifest_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds"),
    resource_mode = "cache"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_true(res$resource_listed[[1]])
  expect_false(res$resource_present[[1]])
  expect_false(res$download_required[[1]])
  expect_false(res$ready_to_build[[1]])
})

test_that("plan_database_build_generic handles fresh mode with present resource", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  resource_dir <- file.path(tmpdir, "genomes")
  dir.create(resource_dir, recursive = TRUE)

  zip_name <- "Freshgenus_genomes.zip"
  zip_path <- file.path(resource_dir, zip_name)
  writeLines("dummy zip content", zip_path)

  manifest_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Freshgenus",
    genus_file_stub = "Freshgenus",
    selection_source = "top_n"
  )

  res <- plan_database_build_generic(
    manifest_tbl = manifest_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds"),
    resource_mode = "fresh"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_true(res$resource_listed[[1]])
  expect_true(res$resource_present[[1]])
  expect_true(res$download_required[[1]])
  expect_true(res$ready_to_build[[1]])
})

test_that("plan_database_build_generic handles fresh mode with missing resource", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  resource_dir <- file.path(tmpdir, "genomes")
  dir.create(resource_dir, recursive = TRUE)

  manifest_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Freshmissing",
    genus_file_stub = "Freshmissing",
    selection_source = "top_n"
  )

  res <- plan_database_build_generic(
    manifest_tbl = manifest_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds"),
    resource_mode = "fresh"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_true(res$resource_listed[[1]])
  expect_false(res$resource_present[[1]])
  expect_true(res$download_required[[1]])
  expect_true(res$ready_to_build[[1]])
})