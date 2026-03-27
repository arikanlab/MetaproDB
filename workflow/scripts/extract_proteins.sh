#!/usr/bin/env bash
set -euo pipefail

rehydrated_dir="${1:?Provide rehydrated genus directory}"
out_fasta="${2:?Provide output FASTA path}"
manifest="${3:?Provide output manifest path}"
biome="${4:?Provide biome id}"
genus="${5:?Provide genus name}"
log="${6:?Provide log path}"

mkdir -p "$(dirname "$out_fasta")"
mkdir -p "$(dirname "$manifest")"
mkdir -p "$(dirname "$log")"

sanitize() {
  echo "$1" | sed -E 's/[^A-Za-z0-9._-]+/_/g'
}

biome_safe="$(sanitize "$biome")"
genus_safe="$(sanitize "$genus")"

{
  : > "$out_fasta"
  echo -e "biome\tgenus\tassembly\tprotein_file" > "$manifest"

  protein_files=()
  while IFS= read -r pf; do
    protein_files+=("$pf")
  done < <(
    find "$rehydrated_dir" -type f \( -path "*/ncbi_dataset/data/*/protein.faa" -o -path "*/ncbi_dataset/data/*/protein.faa.gz" \) | sort
  )

  if [[ ${#protein_files[@]} -eq 0 ]]; then
    echo "WARNING: No protein.faa or protein.faa.gz found for: $rehydrated_dir"
    echo "Leaving empty FASTA and header-only manifest for this genus."
    exit 0
  fi

  for pf in "${protein_files[@]}"; do
    assembly="$(basename "$(dirname "$pf")")"
    echo -e "${biome}\t${genus}\t${assembly}\t${pf}" >> "$manifest"

    if [[ "$pf" == *.gz ]]; then
      gzip -dc "$pf" | awk -v biome="$biome_safe" -v genus="$genus_safe" -v asm="$assembly" '
        /^>/ {
          header = substr($0, 2)
          print ">" biome "|" genus "|" asm "|" header
          next
        }
        { print }
      ' >> "$out_fasta"
    else
      awk -v biome="$biome_safe" -v genus="$genus_safe" -v asm="$assembly" '
        /^>/ {
          header = substr($0, 2)
          print ">" biome "|" genus "|" asm "|" header
          next
        }
        { print }
      ' "$pf" >> "$out_fasta"
    fi

    printf '\n' >> "$out_fasta"
  done

  if [[ ! -s "$out_fasta" ]]; then
    echo "WARNING: Output FASTA is empty after processing: $out_fasta"
    exit 0
  fi

} &> "$log"