test_that("plan_database_build marks present indexed resources correctly", {
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

  genus_index_tbl <- tibble::tibble(
    genus_file_stub = "Testgenus",
    zip_filename = zip_name,
    accession_count = 5,
    resource_version = "0.1.0",
    source_database = "NCBI",
    snapshot_date = "2026-04-03",
    checksum = "abc123",
    file_size_bytes = 100
  )

  res <- plan_database_build(
    manifest_tbl = manifest_tbl,
    genus_index_tbl = genus_index_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds")
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

test_that("plan_database_build marks missing indexed resources for download", {
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

  genus_index_tbl <- tibble::tibble(
    genus_file_stub = "Missinggenus",
    zip_filename = "Missinggenus_genomes.zip",
    accession_count = 3,
    resource_version = "0.1.0",
    source_database = "NCBI",
    snapshot_date = "2026-04-03",
    checksum = "def456",
    file_size_bytes = 200
  )

  res <- plan_database_build(
    manifest_tbl = manifest_tbl,
    genus_index_tbl = genus_index_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds")
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_true(res$resource_listed[[1]])
  expect_false(res$resource_present[[1]])
  expect_true(res$download_required[[1]])
  expect_false(res$ready_to_build[[1]])
})

test_that("plan_database_build handles genera absent from index", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  resource_dir <- file.path(tmpdir, "genomes")
  dir.create(resource_dir, recursive = TRUE)

  manifest_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Unknowngenus",
    genus_file_stub = "Unknowngenus",
    selection_source = "top_n"
  )

  genus_index_tbl <- tibble::tibble(
    genus_file_stub = "Othergenus",
    zip_filename = "Othergenus_genomes.zip",
    accession_count = 2
  )

  res <- plan_database_build(
    manifest_tbl = manifest_tbl,
    genus_index_tbl = genus_index_tbl,
    resource_dir = resource_dir,
    output_root = file.path(tmpdir, "builds")
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  expect_false(res$resource_listed[[1]])
  expect_false(res$resource_present[[1]])
  expect_false(res$download_required[[1]])
  expect_false(res$ready_to_build[[1]])
  expect_true(is.na(res$zip_filename[[1]]))
  expect_true(is.na(res$zip_path[[1]]))
})