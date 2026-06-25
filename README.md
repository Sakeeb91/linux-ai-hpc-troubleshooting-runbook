# Linux Hardware Troubleshooting Runbook for AI/HPC Systems

Practical Linux diagnostics and troubleshooting portfolio project for AI/HPC-style systems. The repository contains a repeatable runbook, safe diagnostic scripts, workflow documents, issue templates, escalation templates, and sample outputs for hardware validation support scenarios.

The project is intentionally honest: it demonstrates troubleshooting discipline for GPU/server environments, not direct certification or production validation of specific enterprise platforms.

## Relevance to AI/HPC Hardware Validation

AI/HPC hardware validation depends on disciplined evidence collection across several layers: system inventory, PCIe visibility, kernel driver binding, GPU runtime availability, thermal and power behavior, storage health, networking state, and logs. A validation technician needs to identify the system under test, collect baseline evidence, isolate the likely failure domain, avoid unsafe changes, document clearly, and escalate with useful technical details.

This project models that workflow for a Linux-based AI/HPC node. It is relevant to server validation, GPU infrastructure troubleshooting, systems integration, technical documentation, and customer-facing support handoffs.

## What this demonstrates

- Linux diagnostics: OS, kernel, CPU, memory, PCIe, devices, processes, services, and system state.
- GPU detection workflow: PCIe detection, driver binding, `nvidia-smi`, GPU count, topology, CUDA/PyTorch visibility, and device-node checks.
- NVIDIA driver troubleshooting: missing driver, driver/library mismatch, Secure Boot, DKMS, kernel update issues, CUDA mismatch, and container GPU access.
- Hardware inventory collection: repeatable capture of CPU, RAM, storage, PCIe devices, network interfaces, optional BMC/IPMI data, and runtime environment.
- Kernel log analysis: `dmesg`, `journalctl`, filtered hardware error patterns, NVIDIA/Xid, PCIe/AER, NVMe/disk, memory/ECC/MCE, thermal, and network clues.
- Thermal and power evidence collection: GPU temperature, power draw, power limit, clocks, throttle reasons, sensors, IPMI readings, and thermal log excerpts.
- Storage and networking checks: block devices, filesystems, NVMe/SMART health, I/O counters, interface state, routes, DNS, NIC driver/firmware clues, and link counters.
- Issue documentation and escalation: templates for expected-versus-actual behavior, reproduction steps, telemetry, suspected failure domain, stop condition, impact, and support request.

## Troubleshooting mindset

The core workflow is:

1. Define the system under test and expected configuration.
2. Record baseline hardware and software state.
3. Reproduce the issue only when safe and authorized.
4. Collect logs, telemetry, and command output.
5. Compare expected behavior with actual behavior.
6. Isolate the likely failure domain.
7. Avoid unsafe changes without approval.
8. Escalate with a clean evidence bundle when needed.
9. Document the final outcome.

## Repository structure

```text
linux-ai-hpc-troubleshooting-runbook/
├── README.md
├── docs/
│   ├── linux_hardware_troubleshooting_runbook.md
│   ├── gpu_detection_workflow.md
│   ├── driver_troubleshooting_workflow.md
│   ├── thermal_troubleshooting_workflow.md
│   ├── storage_troubleshooting_workflow.md
│   ├── networking_troubleshooting_workflow.md
│   ├── memory_cpu_troubleshooting_workflow.md
│   ├── validation_checklist.md
│   ├── issue_report_template.md
│   ├── escalation_template.md
│   └── glossary.md
├── scripts/
│   ├── collect_system_inventory.sh
│   ├── collect_gpu_diagnostics.sh
│   ├── collect_storage_diagnostics.sh
│   ├── collect_network_diagnostics.sh
│   ├── collect_thermal_diagnostics.sh
│   ├── collect_kernel_logs.sh
│   ├── run_full_diagnostic_collection.sh
│   └── validate_project.sh
├── examples/
│   ├── sample_system_inventory.txt
│   ├── sample_gpu_diagnostics.txt
│   ├── sample_kernel_log_excerpt.txt
│   ├── sample_issue_report.md
│   └── sample_escalation_note.md
└── outputs/
    └── .gitkeep
```

## Quickstart

```bash
git clone https://github.com/Sakeeb91/linux-ai-hpc-troubleshooting-runbook.git
cd linux-ai-hpc-troubleshooting-runbook
chmod +x scripts/*.sh
./scripts/validate_project.sh
./scripts/run_full_diagnostic_collection.sh
```

Inspect generated evidence:

```bash
latest=$(ls -td outputs/full_diagnostic_collection_* | head -n 1)
find "$latest" -maxdepth 2 -type f | sort
sed -n '1,160p' "$latest/warning_index.txt"
```

Run individual collectors:

```bash
./scripts/collect_system_inventory.sh
./scripts/collect_gpu_diagnostics.sh
./scripts/collect_storage_diagnostics.sh
./scripts/collect_network_diagnostics.sh
./scripts/collect_thermal_diagnostics.sh
./scripts/collect_kernel_logs.sh
```

External network tests are disabled by default. Enable them only when appropriate:

```bash
RUN_EXTERNAL_TESTS=1 ./scripts/collect_network_diagnostics.sh
```

## Script behavior

- Scripts are read-only diagnostic collectors.
- Scripts create timestamped output folders under `outputs/`.
- Missing optional commands are recorded as warnings and do not stop collection.
- The full collector creates `run_summary.txt`, `output_file_index.txt`, and `warning_index.txt`.
- Generated outputs are ignored by git except for `outputs/.gitkeep`.

## Primary documents

- [Main runbook](docs/linux_hardware_troubleshooting_runbook.md)
- [GPU detection workflow](docs/gpu_detection_workflow.md)
- [NVIDIA driver troubleshooting workflow](docs/driver_troubleshooting_workflow.md)
- [Thermal troubleshooting workflow](docs/thermal_troubleshooting_workflow.md)
- [Storage troubleshooting workflow](docs/storage_troubleshooting_workflow.md)
- [Networking troubleshooting workflow](docs/networking_troubleshooting_workflow.md)
- [Validation checklist](docs/validation_checklist.md)
- [Issue report template](docs/issue_report_template.md)
- [Escalation template](docs/escalation_template.md)

## Example scenario

A GPU is visible in PCIe inventory, but `nvidia-smi` fails after a kernel update.

The workflow checks:

1. Does Linux see the NVIDIA PCIe device?
2. Is the NVIDIA kernel module loaded?
3. Does `nvidia-smi` return a driver/library mismatch?
4. Do DKMS, Secure Boot, kernel logs, or package versions explain the failure?
5. Is the next step safe locally, or should the issue be escalated with logs?

This illustrates the key validation habit: do not jump to a driver reinstall. First preserve evidence, identify the layer that failed, and escalate when remediation requires controlled change approval.

## Limitations

- This project does not replace real enterprise server validation.
- This project does not replace liquid cooling validation.
- This project does not replace firmware validation.
- This project does not replace rack-scale deployment experience.
- This project does not claim hands-on H200/B200 platform experience.
- The scripts do not run stress tests, firmware updates, driver installs, BIOS/BMC changes, filesystem repairs, or destructive disk tests.
- Sample outputs are generic and illustrative; they are not production data-center evidence.

## Next improvements

- NVIDIA DCGM integration.
- NVML-based telemetry.
- Prometheus/Grafana dashboard.
- Automated report generation.
- BMC/IPMI deeper integration.
- Multi-GPU topology checks.
- NCCL/distributed workload diagnostics.
- Containerized GPU diagnostics.
