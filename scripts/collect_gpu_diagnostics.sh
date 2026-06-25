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
  printf 'GPU diagnostic collection\n'
  printf 'Timestamp: %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf 'Kernel: %s\n' "$(uname -a 2>/dev/null || printf unknown)"
  printf 'User: %s\n' "$(whoami 2>/dev/null || printf unknown)"
  printf 'Output directory: %s\n' "$OUTPUT_DIR"
  printf 'Safety: read-only diagnostic collection; no driver changes requested.\n'
} > "${OUTPUT_DIR}/README.txt"

# PCIe visibility and kernel module state.
capture_shell nvidia_pcie_devices 'lspci | grep -i nvidia || true'
capture_shell nvidia_pci_driver_binding 'lspci -nnk -d 10de: || true'
capture_shell nvidia_device_nodes 'ls -l /dev/nvidia* 2>/dev/null || true'
capture_shell loaded_nvidia_modules 'lsmod | grep nvidia || true'
capture_cmd modinfo_nvidia modinfo nvidia

# NVIDIA-SMI snapshots and short telemetry sample.
capture_cmd nvidia_smi nvidia-smi
capture_cmd nvidia_smi_list nvidia-smi -L
capture_cmd nvidia_smi_query nvidia-smi -q
capture_cmd nvidia_smi_gpu_query nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_version,vbios_version,temperature.gpu,power.draw,power.limit,memory.total,memory.used,utilization.gpu,pstate --format=csv
capture_cmd nvidia_smi_health_query nvidia-smi -q -d ECC,PCI,POWER,TEMPERATURE,CLOCK
capture_cmd nvidia_smi_throttle_reasons nvidia-smi --query-gpu=index,clocks_throttle_reasons.active,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown,clocks_throttle_reasons.sw_power_cap --format=csv
capture_cmd nvidia_smi_topology nvidia-smi topo -m
capture_cmd nvidia_smi_dmon nvidia-smi dmon -c 5
capture_cmd nvidia_smi_pmon nvidia-smi pmon -c 5
capture_cmd nvidia_smi_compute_apps nvidia-smi --query-compute-apps=pid,process_name,gpu_uuid,used_memory --format=csv

# Driver, CUDA, and container runtime clues.
capture_cmd nvcc_version nvcc --version
capture_cmd dkms_status dkms status
capture_cmd mokutil_secure_boot mokutil --sb-state
capture_shell cuda_environment 'printf "CUDA_VISIBLE_DEVICES=%s\nLD_LIBRARY_PATH=%s\nPATH=%s\n" "${CUDA_VISIBLE_DEVICES:-}" "${LD_LIBRARY_PATH:-}" "$PATH"'
capture_shell nvidia_cuda_libraries 'ldconfig -p 2>/dev/null | grep -Ei "cuda|nvidia" || true'
capture_cmd docker_info docker info
capture_cmd nvidia_container_cli_info nvidia-container-cli info

# Framework-level CUDA check if Python and PyTorch are present.
if command -v python >/dev/null 2>&1; then
  capture_shell pytorch_cuda_check 'python -c "import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.device_count())"'
elif command -v python3 >/dev/null 2>&1; then
  capture_shell pytorch_cuda_check 'python3 -c "import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.device_count())"'
else
  warn 'Python not found; skipping PyTorch CUDA check'
  printf 'Python not found; skipping PyTorch CUDA check\n' > "${OUTPUT_DIR}/pytorch_cuda_check.txt"
fi

# NVIDIA and PCIe-related kernel log excerpts.
capture_shell dmesg_nvidia 'dmesg | grep -Ei "nvidia|xid|pcie|gpu" || true'
capture_shell journal_nvidia 'journalctl -k --no-pager | grep -Ei "nvidia|xid|pcie|gpu" || true'

printf 'GPU diagnostics written to %s\n' "$OUTPUT_DIR"
