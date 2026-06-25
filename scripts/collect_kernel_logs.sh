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
  printf 'Kernel log collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no log deletion or system changes requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# Full kernel logs where available.
capture_cmd dmesg_full dmesg
capture_cmd journal_kernel journalctl -k --no-pager
capture_cmd journal_current_boot journalctl -b --no-pager
capture_cmd systemctl_failed systemctl --failed --no-pager

# Filtered warning and failure domains.
capture_shell kernel_errors 'dmesg | grep -Ei "error|fail" || true'
capture_shell kernel_thermal 'dmesg | grep -Ei "thermal|temperature|throttle" || true'
capture_shell kernel_nvidia 'dmesg | grep -Ei "nvidia|xid|gpu" || true'
capture_shell kernel_pcie 'dmesg | grep -Ei "pcie|pci express|aer" || true'
capture_shell kernel_memory 'dmesg | grep -Ei "memory|edac|ecc|mce|oom|out of memory" || true'
capture_shell kernel_nvme_disk 'dmesg | grep -Ei "nvme|disk|ata|scsi|i/o|filesystem" || true'
capture_shell kernel_network 'dmesg | grep -Ei "eth|enp|eno|mlx|network|link" || true'
capture_shell journal_errors 'journalctl -k --no-pager | grep -Ei "error|fail|critical|warning" || true'
capture_shell journal_hardware 'journalctl -k --no-pager | grep -Ei "nvidia|xid|pcie|aer|nvme|disk|edac|ecc|mce|thermal|mlx|eth|enp|eno" || true'

printf 'Kernel logs written to %s\n' "$OUTPUT_DIR"
