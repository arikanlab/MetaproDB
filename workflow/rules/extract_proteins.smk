rule extract_proteins:
    input:
        rehydrated = f"{BUILD_DIR}" + "/rehydrated/{genus}_genomes"
    output:
        faa = f"{BUILD_DIR}" + "/proteins/{genus}.faa",
        manifest = f"{BUILD_DIR}" + "/proteins/{genus}.manifest.tsv"
    params:
        biome=lambda wildcards: biome_id_for(wildcards),
        genus=lambda wildcards: genus_name_for(wildcards)
    log:
        f"{BUILD_DIR}" + "/logs/extract_{genus}.log"
    shell:
        """
        bash workflow/scripts/extract_proteins.sh \
            "{input.rehydrated}" \
            "{output.faa}" \
            "{output.manifest}" \
            "{params.biome}" \
            "{params.genus}" \
            "{log}"
        """