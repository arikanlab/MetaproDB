test_that("workflow smoke test completes successfully", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not(nzchar(Sys.which("snakemake")), "snakemake not available")

  res <- system2(
    "bash",
    c("tests/workflow/smoke_test.sh"),
    stdout = TRUE,
    stderr = TRUE
  )

  status <- attr(res, "status")
  expect_equal(if (is.null(status)) 0 else status, 0, info = paste(res, collapse = "\n"))
  expect_true(any(grepl("Smoke test passed", res)), info = paste(res, collapse = "\n"))
})