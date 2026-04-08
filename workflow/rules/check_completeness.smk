rule check_build_completeness:
    input:
        summaries=genus_summaries_for_build()
    output:
        report=BUILD_COMPLETENESS_TSV,
        ok=BUILD_COMPLETENESS_CHECK
    params:
        policy=DOWNLOAD_FAILURE_POLICY,
        min_genome=MIN_GENOME_SUCCESS_FRACTION,
        min_genus=MIN_GENUS_SUCCESS_FRACTION
    run:
        import pandas as pd
        from pathlib import Path

        dfs = [pd.read_csv(path, sep="\t") for path in input.summaries]
        summary = pd.concat(dfs, ignore_index=True)

        summary["expected_genomes"] = pd.to_numeric(summary["expected_genomes"])
        summary["successful_genomes"] = pd.to_numeric(summary["successful_genomes"])

        if "download_status" not in summary.columns:
            summary["download_status"] = "OK"

        n_selected_genera = len(summary)
        n_represented_genera = int((summary["represented"].astype(str).str.upper() == "TRUE").sum())
        n_expected_genomes = int(summary["expected_genomes"].sum())
        n_successful_genomes = int(summary["successful_genomes"].sum())
        n_failed_genomes = int(n_expected_genomes - n_successful_genomes)
        n_download_placeholder = int((summary["download_status"].astype(str).str.upper() != "OK").sum())

        genus_success_fraction = (
            n_represented_genera / n_selected_genera if n_selected_genera > 0 else 0.0
        )
        genome_success_fraction = (
            n_successful_genomes / n_expected_genomes if n_expected_genomes > 0 else 0.0
        )

        if params.policy == "strict":
            passed = (genus_success_fraction == 1.0) and (genome_success_fraction == 1.0)
            decision_mode = "strict"
        else:
            passed = (
                genome_success_fraction >= params.min_genome and
                genus_success_fraction >= params.min_genus
            )
            decision_mode = "permissive"

        overall = pd.DataFrame([{
            "download_failure_policy": params.policy,
            "min_genome_success_fraction": params.min_genome,
            "min_genus_success_fraction": params.min_genus,
            "n_selected_genera": n_selected_genera,
            "n_represented_genera": n_represented_genera,
            "genus_success_fraction": genus_success_fraction,
            "n_expected_genomes": n_expected_genomes,
            "n_successful_genomes": n_successful_genomes,
            "n_failed_genomes": n_failed_genomes,
            "genome_success_fraction": genome_success_fraction,
            "n_download_placeholder_genera": n_download_placeholder,
            "decision": "pass" if passed else "fail",
            "decision_mode": decision_mode
        }])

        Path(output.report).parent.mkdir(parents=True, exist_ok=True)

        with open(output.report, "w") as fh:
            overall.to_csv(fh, sep="\t", index=False)
            fh.write("\n")
            summary.to_csv(fh, sep="\t", index=False)

        if not passed:
            raise ValueError(
                "Build completeness thresholds not met. "
                f"Represented genera: {n_represented_genera}/{n_selected_genera} "
                f"({genus_success_fraction:.3f}); "
                f"Successful genomes: {n_successful_genomes}/{n_expected_genomes} "
                f"({genome_success_fraction:.3f}); "
                f"Placeholder downloads: {n_download_placeholder}."
            )

        Path(output.ok).touch()