test_that("write_snakemake_config writes expected YAML fields", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  config_path <- file.path(tmpdir, "test_config.yml")
  build_plan_path <- file.path(tmpdir, "build_plan.tsv")
  resources_dir <- file.path(tmpdir, "genomes")
  final_database <- file.path(tmpdir, "MetaproDB_test.faa")
  host_proteome <- file.path(tmpdir, "host.faa")

  dir.create(resources_dir, recursive = TRUE)
  writeLines("dummy", build_plan_path)
  writeLines(c(">host_protein", "MPEPTIDE"), host_proteome)

  out <- write_snakemake_config(
    build_plan_path = build_plan_path,
    final_database = final_database,
    resources_dir = resources_dir,
    path = config_path,
    host_proteome = host_proteome
  )

  expect_true(file.exists(config_path))
  expect_equal(out, config_path)

  cfg <- yaml::read_yaml(config_path)

  expect_equal(cfg$build_plan, build_plan_path)
  expect_equal(cfg$resources_dir, resources_dir)
  expect_equal(cfg$final_database, final_database)
  expect_equal(cfg$host_proteome, host_proteome)
})

test_that("write_snakemake_config handles NULL host proteome", {
  tmpdir <- tempfile("metaprodb_test_")
  dir.create(tmpdir, recursive = TRUE)

  config_path <- file.path(tmpdir, "test_config.yml")
  build_plan_path <- file.path(tmpdir, "build_plan.tsv")
  resources_dir <- file.path(tmpdir, "genomes")
  final_database <- file.path(tmpdir, "MetaproDB_test.faa")

  dir.create(resources_dir, recursive = TRUE)
  writeLines("dummy", build_plan_path)

  out <- write_snakemake_config(
    build_plan_path = build_plan_path,
    final_database = final_database,
    resources_dir = resources_dir,
    path = config_path,
    host_proteome = NULL
  )

  expect_true(file.exists(config_path))
  expect_equal(out, config_path)

  cfg <- yaml::read_yaml(config_path)

  expect_equal(cfg$build_plan, build_plan_path)
  expect_equal(cfg$resources_dir, resources_dir)
  expect_equal(cfg$final_database, final_database)
  expect_true("host_proteome" %in% names(cfg))
  expect_true(is.null(cfg$host_proteome))
})

test_that("write_snakemake_config validates scalar character inputs", {
  expect_error(
    write_snakemake_config(
      build_plan_path = NA_character_,
      final_database = "out.faa",
      resources_dir = "resources/genomes",
      path = "config.yml"
    ),
    "`build_plan_path` must be a single non-missing character value."
  )

  expect_error(
    write_snakemake_config(
      build_plan_path = "plan.tsv",
      final_database = NA_character_,
      resources_dir = "resources/genomes",
      path = "config.yml"
    ),
    "`final_database` must be a single non-missing character value."
  )

  expect_error(
    write_snakemake_config(
      build_plan_path = "plan.tsv",
      final_database = "out.faa",
      resources_dir = NA_character_,
      path = "config.yml"
    ),
    "`resources_dir` must be a single non-missing character value."
  )

  expect_error(
    write_snakemake_config(
      build_plan_path = "plan.tsv",
      final_database = "out.faa",
      resources_dir = "resources/genomes",
      path = NA_character_
    ),
    "`path` must be a single non-missing character value."
  )

  expect_error(
    write_snakemake_config(
      build_plan_path = "plan.tsv",
      final_database = "out.faa",
      resources_dir = "resources/genomes",
      path = "config.yml",
      host_proteome = NA_character_
    ),
    "`host_proteome` must be NULL or a single non-missing character value."
  )
})