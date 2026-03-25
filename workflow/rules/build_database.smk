from pathlib import Path

rule build_database:
    input:
        fastas=lambda wildcards: protein_fastas_for_build(),
        manifests=lambda wildcards: protein_manifests_for_build()
    output:
        faa=config["final_database"],
        manifest=str(Path(config["final_database"]).with_suffix(".manifest.tsv"))
    params:
        host=lambda wildcards: config.get("host_proteome", None)
    log:
        str(Path(config["final_database"]).with_suffix(".build.log"))
    shell:
        r"""
        mkdir -p "$(dirname {output.faa})"

        tmp_merged="{output.faa}.tmp"
        host_path="{params.host}"

        cat {input.fastas} > "$tmp_merged"

        if [ "$host_path" != "None" ] && [ "$host_path" != "" ] && [ "$host_path" != "null" ]; then
            if [ ! -f "$host_path" ]; then
                echo "ERROR: host_proteome was provided but file does not exist: $host_path" >&2
                exit 1
            fi
            printf '\n' >> "$tmp_merged"
            cat "$host_path" >> "$tmp_merged"
        fi

        seqkit rmdup -s "$tmp_merged" -o "{output.faa}" > "{log}" 2>&1

        rm -f "$tmp_merged"

        first=1
        : > "{output.manifest}"
        for mf in {input.manifests}; do
            if [ $first -eq 1 ]; then
                cat "$mf" > "{output.manifest}"
                first=0
            else
                tail -n +2 "$mf" >> "{output.manifest}"
            fi
        done
        """