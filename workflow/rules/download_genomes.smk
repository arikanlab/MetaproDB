rule download_genomes:
    output:
        zip = f"{RESOURCES_DIR}" + "/{genus}_genomes.zip"
    params:
        genus=lambda wildcards: genus_name_for(wildcards),
        force_download=lambda wildcards: download_required_for(wildcards)
    log:
        f"{BUILD_DIR}" + "/logs/download_{genus}.log"
    conda:
        "../envs/metaprodb.yml"
    shell:
        """
        bash workflow/scripts/download_one.sh \
            "{params.genus}" \
            "{output.zip}" \
            "{log}" \
            "{params.force_download}"
        """