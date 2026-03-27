rule extract_proteins:
    input:
        src=extract_input_for
    output:
        faa=f"{BUILD_DIR}" + "/proteins/{genus}.faa",
        manifest=f"{BUILD_DIR}" + "/proteins/{genus}.manifest.tsv"
    params:
        biome=lambda wildcards: biome_id_for(wildcards),
        genus=lambda wildcards: genus_name_for(wildcards)
    log:
        f"{BUILD_DIR}" + "/logs/extract_{genus}.log"
    run:
        import shutil
        from pathlib import Path

        src = Path(str(input.src))
        out_faa = Path(str(output.faa))
        out_manifest = Path(str(output.manifest))
        out_faa.parent.mkdir(parents=True, exist_ok=True)

        if src.is_file() and src.suffix == ".faa":
            shutil.copyfile(src, out_faa)
            with open(out_manifest, "w") as fh:
                fh.write("biome_id\tgenus\tprotein_fasta\n")
                fh.write(f"{params.biome}\t{params.genus}\t{output.faa}\n")
            Path(str(log)).touch()
        else:
            shell(
                """
                bash workflow/scripts/extract_proteins.sh \
                    "{input.src}" \
                    "{output.faa}" \
                    "{output.manifest}" \
                    "{params.biome}" \
                    "{params.genus}" \
                    "{log}"
                """
            )