#!/usr/bin/env bash
set -euo pipefail

zip_file="${1:?Provide zip file path}"
genus_dir="${2:?Provide output genus directory}"
log_file="${3:?Provide log file path}"
summary_tsv="${4:?Provide per-genus summary TSV path}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

if [[ ! -f "$zip_file" ]]; then
  echo "Zip path does not exist: $zip_file"
  exit 1
fi

if ! command -v datasets >/dev/null 2>&1; then
  echo "ERROR: 'datasets' command not found in PATH"
  echo "PATH: $PATH"
  exit 1
fi

rm -rf "$genus_dir"
mkdir -p "$genus_dir"
mkdir -p "$(dirname "$log_file")"
mkdir -p "$(dirname "$summary_tsv")"

rehydrate_status=0
expected_genomes=0
successful_genomes=0
represented="FALSE"
download_status="OK"
download_detail=""

{
  echo "ZIP: $zip_file"
  echo "OUT: $genus_dir"
  echo "DATE: $(timestamp)"
  echo "HOST: $(hostname)"
  echo "DATASETS_PATH: $(command -v datasets)"
  echo "DATASETS_VERSION: $(datasets --version || true)"
  echo

  unzip -oq "$zip_file" -d "$genus_dir"

  placeholder_file="$genus_dir/.metaprodb_placeholder.tsv"

  if [[ -f "$placeholder_file" ]]; then
    echo "Detected placeholder zip. Skipping datasets rehydrate."
    download_status="$(awk -F'\t' 'NR==2 {print $2}' "$placeholder_file")"
    download_detail="$(awk -F'\t' 'NR==2 {print $3}' "$placeholder_file")"
    rehydrate_status=0
    expected_genomes=0
    successful_genomes=0
    represented="FALSE"
  else
    set +e
    datasets rehydrate --directory "$genus_dir"
    rehydrate_status=$?
    set -e

    if [[ -d "$genus_dir/ncbi_dataset/data" ]]; then
      expected_genomes=$(find "$genus_dir/ncbi_dataset/data" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
      successful_genomes=$(find "$genus_dir/ncbi_dataset/data" -type f \( -name 'protein.faa' -o -name 'protein.faa.gz' \) | wc -l | tr -d ' ')
    else
      expected_genomes=0
      successful_genomes=0
    fi

    if [[ "$successful_genomes" -ge 1 ]]; then
      represented="TRUE"
    fi
  fi

  echo
  echo "DOWNLOAD_STATUS: $download_status"
  echo "DOWNLOAD_DETAIL: $download_detail"
  echo "REHYDRATE_EXIT_STATUS: $rehydrate_status"
  echo "EXPECTED_GENOMES: $expected_genomes"
  echo "SUCCESSFUL_GENOMES: $successful_genomes"
  echo "REPRESENTED: $represented"

  if [[ "$rehydrate_status" -ne 0 ]]; then
    echo "WARNING: datasets rehydrate returned a non-zero exit status."
  fi

  if [[ "$successful_genomes" -lt 1 ]]; then
    echo "WARNING: No protein.faa files were recovered for this genus."
  fi

  echo
  echo "DONE: $(timestamp)"
} &> "$log_file"

genus_stub="$(basename "$zip_file" _genomes.zip)"
printf "genus_file_stub\texpected_genomes\tsuccessful_genomes\trepresented\trehydrate_exit_status\tdownload_status\tdownload_detail\n" > "$summary_tsv"
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
  "$genus_stub" "$expected_genomes" "$successful_genomes" "$represented" "$rehydrate_status" "$download_status" "$download_detail" >> "$summary_tsv"

echo "Rehydrated $(basename "$zip_file") -> $genus_dir"