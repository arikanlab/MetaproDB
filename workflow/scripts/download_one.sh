#!/usr/bin/env bash
set -euo pipefail

genus="${1:?Provide genus name}"
zip_file="${2:?Provide output zip file path}"
log_file="${3:?Provide log file path}"
force_download="${4:-FALSE}"
failure_policy="${5:-permissive}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

make_placeholder_zip() {
  local zip_path="$1"
  local genus_name="$2"
  local reason="$3"
  local detail="${4:-}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir"

  cat > "$tmpdir/.metaprodb_placeholder.tsv" <<EOF
genus	reason	detail	created_at
$genus_name	$reason	$detail	$(timestamp)
EOF

  python - "$zip_path" "$tmpdir" <<'PY'
import os
import sys
import zipfile

zip_path = sys.argv[1]
src_dir = sys.argv[2]

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(src_dir):
        for f in files:
            full = os.path.join(root, f)
            arc = os.path.relpath(full, src_dir)
            zf.write(full, arc)
PY

  rm -rf "$tmpdir"
}

mkdir -p "$(dirname "$zip_file")"
mkdir -p "$(dirname "$log_file")"

if ! command -v datasets >/dev/null 2>&1; then
  echo "ERROR: 'datasets' command not found in PATH"
  echo "PATH: $PATH"
  exit 1
fi

{
  echo "GENUS: $genus"
  echo "ZIP: $zip_file"
  echo "FORCE_DOWNLOAD: $force_download"
  echo "FAILURE_POLICY: $failure_policy"
  echo "DATE: $(timestamp)"
  echo "HOST: $(hostname)"
  echo "DATASETS_PATH: $(command -v datasets)"
  echo "DATASETS_VERSION: $(datasets --version || true)"
  echo

  rm -f "$zip_file"

  if [[ "$force_download" != "TRUE" ]]; then
    if [[ -s "$zip_file" ]]; then
      echo "Using cached zip: $zip_file"
      echo
      echo "DONE: $(timestamp)"
      exit 0
    fi

    if [[ "$failure_policy" == "strict" ]]; then
      echo "ERROR: Missing cached zip in cache mode: $zip_file"
      exit 1
    else
      echo "WARNING: Missing cached zip in cache mode; creating placeholder zip."
      make_placeholder_zip "$zip_file" "$genus" "MISSING_CACHE_ZIP" "No cached zip available and downloads disabled"
      echo
      echo "DONE: $(timestamp)"
      exit 0
    fi
  fi

  set +e
  datasets download genome taxon "$genus" \
    --include protein \
    --assembly-level complete \
    --assembly-source RefSeq \
    --dehydrated \
    --annotated \
    --assembly-version latest \
    --exclude-multi-isolate \
    --exclude-atypical \
    --reference \
    --filename "$zip_file"
  download_status=$?
  set -e

  echo
  echo "DATASETS_DOWNLOAD_EXIT_STATUS: $download_status"

  if [[ "$download_status" -eq 0 && -s "$zip_file" ]]; then
    echo "Download succeeded."
    echo
    echo "DONE: $(timestamp)"
    exit 0
  fi

  rm -f "$zip_file"

  if [[ "$failure_policy" == "strict" ]]; then
    echo "ERROR: datasets download failed for genus: $genus"
    exit 1
  fi

  echo "WARNING: datasets download failed for genus: $genus"
  echo "WARNING: Creating placeholder zip so downstream completeness checks can evaluate overall success."
  make_placeholder_zip "$zip_file" "$genus" "DOWNLOAD_FAILED" "datasets download genome taxon returned non-zero exit status: $download_status"

  echo
  echo "DONE: $(timestamp)"
} &> "$log_file"

echo "Prepared $genus -> $zip_file"