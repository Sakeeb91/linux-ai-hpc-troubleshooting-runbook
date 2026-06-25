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
  printf 'System inventory collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no system changes requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# Basic identity and OS state.
capture_cmd date date
capture_cmd hostname hostname
capture_cmd hostnamectl hostnamectl
capture_cmd whoami whoami
capture_cmd uptime uptime
capture_cmd timedatectl timedatectl
capture_cmd systemctl_failed systemctl --failed --no-pager
capture_cmd recent_reboots last -x -n 10
capture_cmd uname uname -a
capture_shell os_release 'cat /etc/os-release'

# CPU, memory, storage, and filesystem baseline.
capture_cmd lscpu lscpu
capture_cmd nproc nproc
capture_cmd free_h free -h
capture_cmd swapon_show swapon --show
capture_cmd vmstat vmstat 1 5
capture_cmd numactl_hardware numactl --hardware
capture_cmd lsblk lsblk
capture_cmd lsblk_detailed lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
capture_cmd df_h df -h
capture_cmd findmnt findmnt

# Device inventory. Optional commands are reported as warnings when absent.
capture_cmd lspci lspci
capture_cmd lspci_nnk lspci -nnk
capture_cmd lspci_tree lspci -tv
capture_cmd lspci_verbose lspci -vv
capture_cmd lsusb lsusb
capture_cmd dmidecode dmidecode
capture_cmd lshw_short lshw -short
capture_cmd lsmod lsmod

# Network and management-controller clues are useful for server validation context.
capture_cmd ip_addr ip addr
capture_cmd ip_route ip route
capture_cmd ip_s_link ip -s link
capture_cmd ipmitool_fru ipmitool fru
capture_cmd ipmitool_mc_info ipmitool mc info
capture_cmd ipmitool_sel ipmitool sel list

# Runtime clues often relevant to AI/HPC validation environments.
capture_cmd python_version python --version
capture_cmd python3_version python3 --version
capture_cmd docker_version docker --version

printf 'System inventory written to %s\n' "$OUTPUT_DIR"
