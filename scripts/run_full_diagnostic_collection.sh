#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
OUTPUT_DIR="outputs/full_diagnostic_collection_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"
SUMMARY_FILE="${OUTPUT_DIR}/run_summary.txt"
STATUS=0

{
  printf 'Full diagnostic collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; child scripts avoid system changes.\n\n'
} > "$SUMMARY_FILE"

export DIAG_PARENT_OUTPUT_DIR="$OUTPUT_DIR"

SCRIPTS=(
  collect_system_inventory.sh
  collect_gpu_diagnostics.sh
  collect_storage_diagnostics.sh
  collect_network_diagnostics.sh
  collect_thermal_diagnostics.sh
  collect_kernel_logs.sh
)

for script in "${SCRIPTS[@]}"; do
  {
    printf '## Running %s\n' "$script"
    bash "${SCRIPT_DIR}/${script}"
    printf '\n'
  } >> "$SUMMARY_FILE" 2>&1 || {
    printf 'WARNING: %s returned a non-zero status\n' "$script" | tee -a "$SUMMARY_FILE" >&2
    STATUS=1
  }
done

find "$OUTPUT_DIR" -maxdepth 2 -type f | sort > "${OUTPUT_DIR}/output_file_index.txt"
{
  printf 'Warning index for %s\n\n' "$OUTPUT_DIR"
  found=0
  while IFS= read -r warnings_file; do
    if [[ -s "$warnings_file" ]]; then
      found=1
      printf '## %s\n' "$warnings_file"
      cat "$warnings_file"
      printf '\n'
    fi
  done < <(find "$OUTPUT_DIR" -name warnings.txt -type f | sort)
  if [[ "$found" -eq 0 ]]; then
    printf 'No warnings recorded.\n'
  fi
} > "${OUTPUT_DIR}/warning_index.txt"

printf 'Full diagnostic collection written to %s\n' "$OUTPUT_DIR"
exit "$STATUS"
