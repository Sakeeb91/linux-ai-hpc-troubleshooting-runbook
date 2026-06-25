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
  printf 'Storage diagnostic collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no filesystem repair or destructive tests requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# Device, filesystem, and mount state.
capture_cmd lsblk lsblk
capture_cmd lsblk_detailed lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
capture_cmd df_h df -h
capture_cmd findmnt findmnt
capture_cmd mount mount
capture_cmd blkid blkid
capture_shell mdstat 'cat /proc/mdstat 2>/dev/null || true'
capture_cmd iostat_xz iostat -xz 1 5
capture_cmd vmstat vmstat 1 5

# NVMe inventory and health where available.
capture_cmd nvme_list nvme list
if command -v nvme >/dev/null 2>&1; then
  {
    printf '$ nvme smart-log <detected-nvme-device>\n\n'
    while read -r device; do
      [[ -z "$device" ]] && continue
      printf '## %s\n' "$device"
      nvme smart-log "$device" 2>&1 || true
      printf '\n'
    done < <(lsblk -ndo NAME,TYPE | awk '$2 == "disk" && $1 ~ /^nvme/ {print "/dev/" $1}')
  } > "${OUTPUT_DIR}/nvme_smart_logs.txt"
else
  warn 'Command not found: nvme'
  printf 'Command not found: nvme\n' > "${OUTPUT_DIR}/nvme_smart_logs.txt"
fi

# SMART summary where available. This can require permission on some systems.
if command -v smartctl >/dev/null 2>&1; then
  {
    printf '$ smartctl -a <detected-disk>\n\n'
    while read -r device; do
      [[ -z "$device" ]] && continue
      printf '## %s\n' "$device"
      smartctl -a "$device" 2>&1 || true
      printf '\n'
    done < <(lsblk -ndo NAME,TYPE | awk '$2 == "disk" {print "/dev/" $1}')
  } > "${OUTPUT_DIR}/smartctl_disks.txt"
else
  warn 'Command not found: smartctl'
  printf 'Command not found: smartctl\n' > "${OUTPUT_DIR}/smartctl_disks.txt"
fi

# Storage-related kernel log excerpts.
capture_shell dmesg_storage 'dmesg | grep -Ei "nvme|disk|sda|sdb|scsi|ata|i/o|filesystem|ext4|xfs|btrfs|error|fail" || true'
capture_shell journal_storage 'journalctl -k --no-pager | grep -Ei "nvme|disk|scsi|ata|i/o|filesystem|ext4|xfs|btrfs|error|fail" || true'

printf 'Storage diagnostics written to %s\n' "$OUTPUT_DIR"
