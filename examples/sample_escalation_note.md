# Sample Escalation Note

This is a sample escalation note for a hypothetical lab issue.

## Short Summary

`lab-linux-node-01` has an NVIDIA GPU visible in PCIe inventory, but `nvidia-smi` fails after a kernel update. Evidence suggests a driver/library or DKMS module mismatch.

## Business/Customer Impact

- Affected workflow: AI/HPC validation lab testing
- Impact: GPU validation and CUDA workload checks cannot proceed
- Duration: observed after reboot on 2026-06-25
- Workaround available: none confirmed

## System Details

- Hostname: `lab-linux-node-01`
- Server model: Generic Linux workstation/server
- CPU: Generic x86_64 CPU
- GPU: 1 generic NVIDIA data-center-style GPU
- RAM: 128 GiB
- Storage: NVMe boot/data drive
- NIC/fabric: Ethernet

## Hardware/Software Versions

- OS version: Ubuntu 24.04 LTS sample
- Kernel version: `6.8.0-generic`
- NVIDIA driver expected: `555.00.00`
- NVIDIA kernel module observed: sample mismatch with `550.00.00`
- CUDA: expected 12.x compatibility

## Reproduction Steps

1. Run `lspci | grep -i nvidia` and confirm GPU appears.
2. Run `lsmod | grep nvidia` and confirm NVIDIA module is loaded.
3. Run `nvidia-smi` and observe driver/library mismatch error.

## Evidence Collected

- `lspci | grep -i nvidia`
- `lsmod | grep nvidia`
- `modinfo nvidia`
- `nvidia-smi`
- `dkms status`
- `journalctl -k | grep -i nvidia`

## What Has Already Been Tried

Only read-only diagnostics were run. No reboot, driver reinstall, DKMS rebuild, Secure Boot change, or hardware action was performed.

## Support Needed

Please confirm the approved remediation path for the current kernel and NVIDIA driver stack. Options may include DKMS rebuild, package repair, approved driver reinstall, or rollback according to lab policy.

## Urgency

Medium. Lab GPU validation is blocked, but the node remains reachable.

## Attachments

- GPU diagnostic output directory
- Kernel log excerpt
- `nvidia-smi` error output
