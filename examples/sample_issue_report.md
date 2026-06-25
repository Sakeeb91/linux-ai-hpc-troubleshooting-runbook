# Sample Issue Report: GPU Visible In PCIe But `nvidia-smi` Fails After Kernel Update

This is a sample scenario for portfolio documentation. It does not describe a real customer or production system.

## Date/Time

2026-06-25 15:30 EDT

## Reporter

Portfolio lab technician

## System Under Test

- Hostname: `lab-linux-node-01`
- Server model: Generic Linux workstation/server
- CPU: Generic x86_64 CPU, 32 threads
- GPU: 1 generic NVIDIA data-center-style GPU
- RAM: 128 GiB
- Storage: 1 NVMe boot/data drive
- Network: 1 Ethernet NIC

## Environment

- OS version: Ubuntu 24.04 LTS sample
- Kernel version: `6.8.0-generic`
- NVIDIA driver version: expected `555.00.00`
- CUDA version: expected CUDA 12.x compatibility
- Recent change: kernel update and reboot

## Severity

Medium for lab validation. GPU workloads cannot start, but system remains reachable.

## Summary

The GPU is visible in PCIe inventory, but `nvidia-smi` fails after a kernel update. Initial evidence suggests the NVIDIA kernel module and user-space library versions may not match.

## Expected Behavior

`nvidia-smi` should display the GPU, driver version, temperature, power, memory, and process table.

## Actual Behavior

`nvidia-smi` returns a driver/library mismatch error.

## Steps To Reproduce

1. Log in to `lab-linux-node-01`.
2. Run `lspci | grep -i nvidia`.
3. Run `nvidia-smi`.

## Commands Run

```bash
uname -a
lspci | grep -i nvidia
lsmod | grep nvidia
modinfo nvidia
nvidia-smi
dkms status
journalctl -k | grep -i nvidia
```

## Relevant Logs

```text
NVRM: API mismatch: the client has the version 555.00.00, but this kernel module has the version 550.00.00.
```

## Telemetry Observed

- GPU temperature: unavailable because `nvidia-smi` failed.
- Power draw: unavailable because `nvidia-smi` failed.
- CPU load: normal.
- Memory usage: normal.
- Storage state: no obvious issue.
- Network state: system reachable over SSH.

## Suspected Failure Domain

Driver/kernel module mismatch after kernel update.

## Attempted Remediation

No driver changes were made. Evidence was collected only.

## Current Status

Open. Escalation recommended before driver repair or reboot action.

## Recommended Next Action

Confirm approved NVIDIA driver version for the current kernel and decide whether to rebuild DKMS module, reinstall the driver package, or roll back according to change-control policy.

## Attachments/Evidence

- `outputs/collect_gpu_diagnostics_sample/`
- `nvidia-smi` error output
- `modinfo nvidia`
- `dkms status`
- NVIDIA-related kernel logs
