#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-tests/workflow/config/smoke_config.yml}"
SNAKEFILE="${2:-workflow/Snakefile}"

echo "Running MetaproDB workflow smoke test"
echo "Config: $CONFIG"
echo "Snakefile: $SNAKEFILE"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Config file not found: $CONFIG"
  exit 1
fi

if [[ ! -f "$SNAKEFILE" ]]; then
  echo "ERROR: Snakefile not found: $SNAKEFILE"
  exit 1
fi

if [[ -z "${CONDA_PREFIX:-}" ]]; then
  echo "ERROR: No active conda environment detected. Please activate the metaprodb environment first."
  exit 1
fi

PYTHON_BIN="${CONDA_PREFIX}/bin/python"

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "ERROR: Python not found in active conda environment: $PYTHON_BIN"
  exit 1
fi

if ! "$PYTHON_BIN" -c "import yaml" >/dev/null 2>&1; then
  echo "ERROR: PyYAML is not available in $PYTHON_BIN"
  exit 1
fi

snakemake -s "$SNAKEFILE" --configfile "$CONFIG" --cores 2 --use-conda --quiet

final_db="$("$PYTHON_BIN" - "$CONFIG" <<'PY'
import sys
import yaml

config_path = sys.argv[1]
with open(config_path) as f:
    cfg = yaml.safe_load(f)

print(cfg["final_database"])
PY
)"

final_manifest="${final_db%.faa}.manifest.tsv"

if [[ ! -s "$final_db" ]]; then
  echo "ERROR: Final database missing or empty: $final_db"
  exit 1
fi

if [[ ! -s "$final_manifest" ]]; then
  echo "ERROR: Final manifest missing or empty: $final_manifest"
  exit 1
fi

seq_count=$(grep -c '^>' "$final_db" || true)
if [[ "$seq_count" -lt 1 ]]; then
  echo "ERROR: Final database contains no FASTA entries: $final_db"
  exit 1
fi

echo "Smoke test passed"
echo "  FASTA:     $final_db"
echo "  Manifest:  $final_manifest"
echo "  Sequences: $seq_count"