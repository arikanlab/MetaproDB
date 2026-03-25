#!/usr/bin/env bash
set -euo pipefail

genus="${1:?Provide genus name}"
zip_file="${2:?Provide output zip file path}"
log_file="${3:?Provide log file path}"
force_download="${4:-FALSE}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

mkdir -p "$(dirname "$zip_file")"
mkdir -p "$(dirname "$log_file")"

if ! command -v datasets >/dev/null 2>&1; then
  echo "ERROR: 'datasets' command not found in PATH"
  echo "PATH: $PATH"
  exit 1
fi

if [[ "$force_download" != "TRUE" ]]; then
  if [[ -s "$zip_file" ]]; then
    echo "Using cached zip: $zip_file"
    exit 0
  else
    echo "Missing cached zip in cache mode: $zip_file"
    exit 1
  fi
fi

{
  echo "GENUS: $genus"
  echo "ZIP: $zip_file"
  echo "FORCE_DOWNLOAD: $force_download"
  echo "DATE: $(timestamp)"
  echo "HOST: $(hostname)"
  echo "DATASETS_PATH: $(command -v datasets)"
  echo "DATASETS_VERSION: $(datasets --version || true)"
  echo

  rm -f "$zip_file"

  datasets download genome taxon "$genus" \
    --include protein \
    --assembly-level complete \
    --dehydrated \
    --filename "$zip_file"

  echo
  echo "DONE: $(timestamp)"
} &> "$log_file"

echo "Downloaded $genus -> $zip_file"