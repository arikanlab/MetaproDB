#!/usr/bin/env bash
set -euo pipefail

zip_file="${1:?Provide zip file path}"
genus_dir="${2:?Provide output genus directory}"
log_file="${3:?Provide log file path}"

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

if [[ -d "$genus_dir/ncbi_dataset/data" ]]; then
  echo "Already rehydrated, skipping: $genus_dir"
  exit 0
fi

mkdir -p "$genus_dir"
mkdir -p "$(dirname "$log_file")"

{
  echo "ZIP: $zip_file"
  echo "OUT: $genus_dir"
  echo "DATE: $(timestamp)"
  echo "HOST: $(hostname)"
  echo "DATASETS_PATH: $(command -v datasets)"
  echo "DATASETS_VERSION: $(datasets --version || true)"
  echo

  unzip -oq "$zip_file" -d "$genus_dir"
  datasets rehydrate --directory "$genus_dir"

  echo
  echo "DONE: $(timestamp)"
} &> "$log_file"

echo "Rehydrated $(basename "$zip_file") -> $genus_dir"