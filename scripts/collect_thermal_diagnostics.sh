#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SCRIPT_NAME="$(basename "$0" .sh)"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
if [[ -n "${DIAG_PARENT_OUTPUT_DIR:-}" ]]; then
  OUTPUT_DIR="${DIAG_PARENT_OUTPUT_DIR}/${SCRIPT_NAME}"
else
  OUTPUT_DIR="outputs/${SCRIPT_NAME}_${TIMESTAMP}"
fi
mkdir -p "$OUTPUT_DIR"
WARNINGS_FILE="${OUTPUT_DIR}/warnings.txt"

warn() {
  printf 'WARNING: %s\n' "$*" | tee -a "$WARNINGS_FILE" >&2
}

capture_cmd() {
  local name="$1"
  shift
  local cmd="$1"
  local outfile="${OUTPUT_DIR}/${name}.txt"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "Command not found: $cmd"
    printf 'Command not found: %s\n' "$cmd" > "$outfile"
    return 0
  fi

  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } > "$outfile" 2>&1 || warn "Command failed: $*"
}

capture_shell() {
  local name="$1"
  local command_text="$2"
  local outfile="${OUTPUT_DIR}/${name}.txt"

  {
    printf '$ %s\n\n' "$command_text"
    bash -c "$command_text"
  } > "$outfile" 2>&1 || warn "Command failed: $command_text"
}

{
  printf 'Thermal diagnostic collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no fan, BMC, BIOS, or power-policy changes requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# Host and platform sensors where available.
capture_cmd sensors sensors
capture_cmd ipmitool_sensor ipmitool sensor
capture_cmd ipmitool_sel ipmitool sel list
capture_cmd ipmitool_fru ipmitool fru

# NVIDIA temperature and power telemetry where available.
capture_cmd nvidia_smi nvidia-smi
capture_cmd nvidia_temperature_power nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.current.memory,utilization.gpu,pstate --format=csv
capture_cmd nvidia_throttle_reasons nvidia-smi --query-gpu=index,clocks_throttle_reasons.active,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown,clocks_throttle_reasons.sw_power_cap --format=csv
capture_cmd nvidia_dmon nvidia-smi dmon -c 5

# Thermal-related kernel log excerpts.
capture_shell dmesg_thermal 'dmesg | grep -Ei "thermal|temperature|throttle|power" || true'
capture_shell journal_thermal 'journalctl -k --no-pager | grep -Ei "thermal|temperature|throttle|power" || true'

cat > "${OUTPUT_DIR}/classification_template.txt" <<'EOF'
Thermal classification:

PASS:
- Stable temperature within expected range during workload.

WARNING:
- High but stable temperature, possible cooling margin issue.

FAIL:
- Thermal protection event, repeated throttling, or uncontrolled temperature rise.

Notes:
- Add workload name, start/end time, idle values, load values, and any thermal log messages.
EOF

printf 'Thermal diagnostics written to %s\n' "$OUTPUT_DIR"
