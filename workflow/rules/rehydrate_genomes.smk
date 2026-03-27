rule rehydrate_genomes:
    input:
        zip=f"{RESOURCES_DIR}" + "/{genus}_genomes.zip"
    output:
        rehydrated=directory(f"{BUILD_DIR}" + "/rehydrated/{genus}_genomes"),
        summary=f"{BUILD_DIR}" + "/rehydration_summary/{genus}.tsv"
    log:
        f"{BUILD_DIR}" + "/logs/rehydrate_{genus}.log"
    conda:
        "../envs/metaprodb.yml"
    shell:
        r"""
        bash workflow/scripts/rehydrate_one.sh \
            "{input.zip}" \
            "{output.rehydrated}" \
            "{log}" \
            "{output.summary}"
        """