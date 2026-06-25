# AI/HPC Linux Node Validation Checklist

Use this checklist for a basic, non-destructive validation pass on a Linux node intended for AI/HPC-style workloads.

## Pre-Test

- [ ] Confirm system identity.
- [ ] Record OS and kernel version.
- [ ] Record CPU, RAM, and storage inventory.
- [ ] Record expected GPU count.
- [ ] Record detected GPU count.
- [ ] Record NVIDIA driver and CUDA versions where available.
- [ ] Confirm network interfaces are detected.
- [ ] Confirm available disk space.
- [ ] Capture baseline kernel logs.
- [ ] Record test date and technician.

## GPU Validation

- [ ] `nvidia-smi` works where NVIDIA GPUs are expected.
- [ ] GPU count matches expected configuration.
- [ ] GPU memory appears correct.
- [ ] Driver version is recorded.
- [ ] GPU topology is captured.
- [ ] Basic CUDA or PyTorch check passes where available.
- [ ] GPU telemetry capture works.
- [ ] NVIDIA-related kernel log excerpts are captured.

## Thermal And Power

- [ ] Idle temperature is recorded.
- [ ] Load temperature is recorded if a workload is authorized.
- [ ] Power draw is recorded.
- [ ] No obvious thermal errors appear in kernel logs.
- [ ] Thermal result is classified as pass, warning, or fail.

## Storage

- [ ] Disks are detected.
- [ ] Filesystems are mounted as expected.
- [ ] Sufficient free space is available.
- [ ] No obvious disk, NVMe, or filesystem errors appear in logs.
- [ ] SMART or NVMe health data is collected where available.

## Networking

- [ ] Interfaces are detected.
- [ ] Expected links are up.
- [ ] IP configuration is present.
- [ ] Basic connectivity passes where external or internal ping tests are authorized.
- [ ] NIC driver and firmware clues are captured where available.

## CPU And Memory

- [ ] CPU model, socket, core, and thread count are recorded.
- [ ] Memory capacity is recorded.
- [ ] Swap usage is checked.
- [ ] Process-level CPU and memory pressure is reviewed.
- [ ] NUMA layout is recorded where relevant.
- [ ] Kernel logs are checked for memory, machine-check, or corrected-error messages.

## Post-Test

- [ ] Logs are collected.
- [ ] Outputs are stored under a timestamped directory.
- [ ] Issues are documented.
- [ ] Pass/fail status is assigned.
- [ ] Escalation note is created if needed.
- [ ] Final outcome is documented.
