test_that("summarize_database_build returns expected QC structure", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  rehydrated_dir <- file.path(tmpdir, "rehydrated", "Testgenus_genomes")
  proteins_dir <- file.path(tmpdir, "proteins")
  dir.create(rehydrated_dir, recursive = TRUE)
  dir.create(proteins_dir, recursive = TRUE)

  protein_fasta <- file.path(proteins_dir, "Testgenus.faa")
  writeLines(c(">prot1", "MPEPTIDE", ">prot2", "MSEQ"), protein_fasta)

  final_database <- file.path(tmpdir, "MetaproDB_test.faa")
  writeLines(c(">prot1", "MPEPTIDE", ">prot2", "MSEQ"), final_database)

  final_manifest <- sub("\\.faa$", ".manifest.tsv", final_database)
  readr::write_tsv(
    tibble::tibble(
      genus = "Testgenus",
      protein_id = c("prot1", "prot2")
    ),
    final_manifest
  )

  build_plan_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Testgenus",
    genus_file_stub = "Testgenus",
    selection_source = "top_n",
    zip_filename = "Testgenus_genomes.zip",
    zip_path = file.path(tmpdir, "genomes", "Testgenus_genomes.zip"),
    resource_listed = TRUE,
    resource_present = TRUE,
    download_required = FALSE,
    rehydrated_dir = rehydrated_dir,
    protein_fasta = protein_fasta,
    ready_to_build = TRUE
  )

  qc <- summarize_database_build(
    build_plan = build_plan_tbl,
    final_database = final_database,
    final_manifest = final_manifest
  )

  expect_true(is.list(qc))
  expect_true(all(c("summary", "genus_status", "missing_genera") %in% names(qc)))

  expect_s3_class(qc$summary, "tbl_df")
  expect_s3_class(qc$genus_status, "tbl_df")
  expect_true(is.character(qc$missing_genera))

  expect_equal(nrow(qc$summary), 1)
  expect_equal(qc$summary$n_selected_genera[[1]], 1)
  expect_equal(qc$summary$n_protein_fastas_found[[1]], 1)
  expect_true(qc$summary$final_database_exists[[1]])
  expect_true(qc$summary$final_manifest_exists[[1]])
  expect_equal(qc$summary$post_dedup_sequences[[1]], 2)
  expect_equal(qc$summary$final_manifest_rows[[1]], 2)

  expect_equal(nrow(qc$genus_status), 1)
  expect_true(qc$genus_status$protein_fasta_exists[[1]])
  expect_true(qc$genus_status$rehydrated_dir_exists[[1]])
  expect_equal(qc$genus_status$protein_fasta_sequences[[1]], 2)

  expect_length(qc$missing_genera, 0)
})

test_that("write_build_qc_report writes expected output files", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  qc_report <- list(
    summary = tibble::tibble(
      biome_id = "testbiome",
      n_selected_genera = 1
    ),
    genus_status = tibble::tibble(
      genus = "Testgenus",
      protein_fasta_exists = TRUE
    ),
    missing_genera = character(0)
  )

  outdir <- file.path(tmpdir, "qc")

  out <- write_build_qc_report(
    qc_report = qc_report,
    output_dir = outdir,
    prefix = "testbuild"
  )

  expect_equal(out, outdir)
  expect_true(file.exists(file.path(outdir, "testbuild.summary.tsv")))
  expect_true(file.exists(file.path(outdir, "testbuild.genus_status.tsv")))
  expect_true(file.exists(file.path(outdir, "testbuild.missing_genera.txt")))
})

test_that("write_build_provenance writes provenance table", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  rehydrated_dir <- file.path(tmpdir, "rehydrated", "Testgenus_genomes")
  proteins_dir <- file.path(tmpdir, "proteins")
  dir.create(rehydrated_dir, recursive = TRUE)
  dir.create(proteins_dir, recursive = TRUE)

  protein_fasta <- file.path(proteins_dir, "Testgenus.faa")
  writeLines(c(">prot1", "MPEPTIDE", ">prot2", "MSEQ"), protein_fasta)

  final_database <- file.path(tmpdir, "MetaproDB_test.faa")
  writeLines(c(">prot1", "MPEPTIDE", ">prot2", "MSEQ"), final_database)

  final_manifest <- sub("\\.faa$", ".manifest.tsv", final_database)
  readr::write_tsv(
    tibble::tibble(
      genus = "Testgenus",
      protein_id = c("prot1", "prot2")
    ),
    final_manifest
  )

  build_plan_tbl <- tibble::tibble(
    biome_id = "testbiome",
    genus = "Testgenus",
    genus_file_stub = "Testgenus",
    selection_source = "top_n",
    zip_filename = "Testgenus_genomes.zip",
    zip_path = file.path(tmpdir, "genomes", "Testgenus_genomes.zip"),
    resource_listed = TRUE,
    resource_present = TRUE,
    download_required = FALSE,
    rehydrated_dir = rehydrated_dir,
    protein_fasta = protein_fasta,
    ready_to_build = TRUE
  )

  provenance_path <- file.path(tmpdir, "provenance.tsv")

  out <- write_build_provenance(
    build_plan = build_plan_tbl,
    final_database = final_database,
    final_manifest = final_manifest,
    output_path = provenance_path,
    host_proteome = NULL,
    resource_mode = "cache",
    genus_index_used = "resources/genus_index.tsv"
  )

  expect_equal(out, provenance_path)
  expect_true(file.exists(provenance_path))

  prov <- readr::read_tsv(provenance_path, show_col_types = FALSE)

  expect_equal(nrow(prov), 1)
  expect_equal(prov$biome_id[[1]], "testbiome")
  expect_equal(prov$n_selected_genera[[1]], 1)
  expect_equal(prov$n_protein_fastas_found[[1]], 1)
  expect_equal(prov$post_dedup_sequences[[1]], 2)
  expect_equal(prov$resource_mode[[1]], "cache")
  expect_equal(prov$genus_index_used[[1]], "resources/genus_index.tsv")
})
