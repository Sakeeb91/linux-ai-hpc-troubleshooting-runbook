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
  printf 'Network diagnostic collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no network configuration changes requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# Interface, route, and socket state.
capture_cmd ip_addr ip addr
capture_cmd ip_link ip link
capture_cmd ip_s_link ip -s link
capture_cmd ip_route ip route
capture_cmd ss_tulpn ss -tulpn

# NIC inventory and driver clues.
capture_shell pci_network_devices 'lspci | grep -Ei "ethernet|network|mellanox|broadcom|intel" || true'
capture_shell pci_network_driver_binding 'lspci -nnk | grep -A3 -Ei "ethernet|network|mellanox|broadcom|intel" || true'
capture_shell dmesg_network 'dmesg | grep -Ei "eth|enp|eno|mlx|network|firmware|link|error|fail" || true'

if command -v ethtool >/dev/null 2>&1; then
  {
    printf '$ ethtool <detected-interface>\n\n'
    if [[ -d /sys/class/net ]]; then
      for iface_path in /sys/class/net/*; do
        [[ -e "$iface_path" ]] || continue
        iface="$(basename "$iface_path")"
        [[ "$iface" == "lo" ]] && continue
        printf '## %s\n' "$iface"
        ethtool "$iface" 2>&1 || true
        printf '\n## %s driver\n' "$iface"
        ethtool -i "$iface" 2>&1 || true
        printf '\n## %s counters\n' "$iface"
        ethtool -S "$iface" 2>&1 || true
        printf '\n'
      done
    else
      printf '/sys/class/net not found; skipping interface enumeration.\n'
    fi
  } > "${OUTPUT_DIR}/ethtool_interfaces.txt"
else
  warn 'Command not found: ethtool'
  printf 'Command not found: ethtool\n' > "${OUTPUT_DIR}/ethtool_interfaces.txt"
fi

# DNS configuration and optional external connectivity tests.
capture_shell dns_config 'cat /etc/resolv.conf'
capture_cmd resolvectl_status resolvectl status
capture_cmd getent_google getent hosts google.com
if [[ "${RUN_EXTERNAL_TESTS:-0}" == "1" ]]; then
  capture_cmd ping_8_8_8_8 ping -c 4 8.8.8.8
  capture_cmd ping_google ping -c 4 google.com
  capture_cmd traceroute_google traceroute google.com
else
  {
    printf 'External connectivity tests were skipped.\n'
    printf 'Set RUN_EXTERNAL_TESTS=1 to run ping/traceroute checks to 8.8.8.8 and google.com.\n'
  } > "${OUTPUT_DIR}/external_connectivity_tests.txt"
fi

printf 'Network diagnostics written to %s\n' "$OUTPUT_DIR"
