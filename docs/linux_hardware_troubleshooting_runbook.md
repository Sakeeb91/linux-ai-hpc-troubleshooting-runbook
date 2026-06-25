# Linux Hardware Troubleshooting Runbook

## Purpose

Hardware validation and systems integration require repeatable diagnostics, clean evidence collection, and structured escalation. This runbook provides a practical process for investigating Linux-based AI/HPC-style nodes while avoiding unsafe changes and preserving the evidence needed for engineering or vendor follow-up.

The focus is disciplined troubleshooting: identify the system under test, capture baseline state, reproduce symptoms when safe, collect telemetry, isolate the likely failure domain, and document the outcome.

## Diagnostic Mindset

Use the same structure for every investigation:

1. Define the system under test.
2. Record baseline hardware and software state.
3. Reproduce the issue, if safe and authorized.
4. Collect logs and telemetry.
5. Compare expected behavior with actual behavior.
6. Identify the likely failure domain.
7. Apply safe remediation only when approved.
8. Escalate with evidence if unresolved.
9. Document the final outcome.

## Repeatable Troubleshooting Process

The goal is not to run every command. The goal is to answer a sequence of questions with evidence.

| Stage | Question | Evidence | Decision |
| --- | --- | --- | --- |
| Intake | What is the expected system configuration and business impact? | Ticket, asset record, customer report, expected GPU/NIC/storage count, severity | Decide urgency and scope. |
| Baseline | What does Linux currently see? | OS, kernel, CPU, memory, PCIe, storage, network, GPU inventory | Identify expected-versus-actual gaps. |
| Reproduction | Can the issue be reproduced safely? | Exact command, workload, timestamp, error text, current user, environment | Avoid unsafe or destructive reproduction. |
| Domain isolation | Which layer is failing? | PCIe/device visibility, driver binding, runtime libraries, container access, workload logs, thermal/power data | Pick the next workflow. |
| Evidence bundle | What would another engineer need? | Timestamped outputs, versions, logs, telemetry, attempted actions | Escalate or continue locally. |
| Closeout | What changed and what is the final state? | Pass/fail, mitigation, permanent fix, open risk, owner | Document outcome. |

## Stop Conditions

Stop local troubleshooting and escalate when the next action would require:

- Physical hardware service, reseating, cabling changes, or part replacement.
- BIOS, BMC, firmware, Secure Boot, or bootloader changes.
- Driver installation, removal, downgrade, DKMS rebuild, or reboot on a shared/customer-impacting system.
- Filesystem repair, destructive disk testing, partitioning, or data deletion.
- Stress, burn-in, or high-power workload execution without explicit approval.
- Network switch, VLAN, fabric, or customer routing changes.

## System Under Test Template

| Field | Value |
| --- | --- |
| Hostname | |
| Server model | |
| Asset tag / ticket / case ID | |
| Severity / customer impact | |
| CPU | |
| GPU | |
| Expected GPU count | |
| Actual GPU count | |
| RAM | |
| Storage | |
| Network interfaces | |
| Expected NIC link speed/fabric | |
| OS version | |
| Kernel version | |
| NVIDIA driver version | |
| CUDA version | |
| Container runtime / orchestration, if relevant | |
| BIOS/BMC firmware version, if available | |
| Cooling method, if known | |
| Rack/location, if applicable | |
| Recent changes | |
| Test date | |
| Technician | |

## Baseline Collection Checklist

- Record the exact hostname, operating system, kernel, and date.
- Record CPU model, core count, memory size, storage layout, and network interfaces.
- Record GPU model, count, driver version, CUDA version, and topology where available.
- Capture kernel logs before rebooting or changing drivers.
- Capture expected configuration from ticket, asset record, purchase order, vendor spec, or lab note.
- Clearly label assumptions and unknowns.
- Record which commands failed due to missing tools or permissions.
- Create a single timestamped output folder and keep raw evidence unchanged.

## Linux Command Reference

### System

| Command | Use |
| --- | --- |
| `uname -a` | Shows kernel version, architecture, and build details. Useful for driver compatibility checks. |
| `hostnamectl` | Shows hostname, operating system, virtualization status, and chassis information where available. |
| `lsb_release -a` | Shows distribution information on systems that provide `lsb_release`. |
| `cat /etc/os-release` | Portable way to record Linux distribution and version. |
| `uptime` | Shows current uptime and load averages. Useful for understanding recent reboot history and system pressure. |
| `whoami` | Confirms current user context. Useful when permissions affect diagnostics. |
| `date` | Records when evidence was collected. |
| `dmesg` | Shows kernel ring buffer messages, often including hardware, driver, PCIe, storage, and thermal errors. |
| `journalctl` | Reads systemd journal logs. Useful for boot, driver, and service-level evidence. |
| `journalctl -b` | Shows logs from the current boot. Useful when a problem started after reboot. |
| `systemctl --failed` | Lists failed systemd units that may explain missing services or drivers. |
| `last -x` | Shows reboot and shutdown history where available. |
| `timedatectl` | Confirms time sync and timezone, important for correlating logs. |

### CPU

| Command | Use |
| --- | --- |
| `lscpu` | Summarizes CPU model, cores, threads, sockets, NUMA nodes, virtualization, and architecture. |
| `nproc` | Shows available processing units. Quick cross-check against `lscpu`. |
| `cat /proc/cpuinfo` | Provides detailed per-core CPU information. |
| `top` | Shows live process and CPU utilization. |
| `htop` | Interactive process viewer if installed. Useful for process-level triage. |
| `mpstat` | Shows CPU utilization by processor if `sysstat` is installed. |
| `pidstat` | Shows per-process CPU, memory, and I/O statistics if `sysstat` is installed. |

### Memory

| Command | Use |
| --- | --- |
| `free -h` | Shows memory and swap usage in human-readable format. |
| `cat /proc/meminfo` | Provides detailed kernel memory counters. |
| `dmidecode -t memory` | Shows memory slot and DIMM details when installed and permitted. Often requires elevated permission. |
| `vmstat` | Shows memory, swap, I/O, process, and CPU scheduling counters. |
| `swapon --show` | Shows active swap devices/files and usage. |
| `numactl --hardware` | Shows NUMA nodes and memory locality where available. |

### PCIe And Devices

| Command | Use |
| --- | --- |
| `lspci` | Lists PCIe devices, including GPUs, NICs, storage controllers, and bridge devices. |
| `lspci -nnk` | Shows vendor/device IDs and kernel driver binding. Very useful for GPU/NIC driver triage. |
| `lspci -vv` | Provides verbose PCIe details, useful for driver binding and link state clues. |
| `lspci -tv` | Shows PCIe tree topology. Useful for understanding device placement behind bridges or switches. |
| `lsusb` | Lists USB devices if available. |
| `dmidecode` | Shows BIOS, chassis, system, and hardware table data where available. Often requires elevated permission. |
| `lshw` | Provides hardware inventory if installed. |
| `udevadm info --query=property --path=<sysfs-path>` | Shows udev properties for a device when deeper device identity is needed. |

### Storage

| Command | Use |
| --- | --- |
| `lsblk` | Shows block devices, partitions, sizes, and mount points. |
| `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL` | Captures richer disk identity and mount information. |
| `df -h` | Shows filesystem capacity and free space. |
| `findmnt` | Shows mount tree and source devices. |
| `blkid` | Shows block device identifiers and filesystem types. |
| `smartctl` | Reads SMART health data when installed and supported by the device. |
| `nvme list` | Lists NVMe devices when the NVMe CLI is installed. |
| `nvme smart-log /dev/nvmeX` | Captures NVMe health counters. Use confirmed device names only. |
| `iostat -xz 1 5` | Shows I/O utilization, latency, and queue statistics if `sysstat` is installed. |
| `dmesg \| grep -i error` | Filters kernel messages for error patterns. Combine with storage-specific filters. |

### Networking

| Command | Use |
| --- | --- |
| `ip addr` | Shows IP addresses and interface state. |
| `ip link` | Shows interface administrative and carrier state. |
| `ip -s link` | Shows interface counters, errors, and drops. |
| `ip route` | Shows routing table. |
| `ethtool <interface>` | Shows link speed, duplex, driver, and supported modes if installed. |
| `ethtool -i <interface>` | Shows NIC driver and firmware versions. |
| `ethtool -S <interface>` | Shows NIC hardware counters where supported. |
| `lspci \| grep -i ethernet` | Lists PCIe Ethernet controllers. |
| `ping <target>` | Tests basic reachability. |
| `traceroute <target>` | Shows route path if installed. |
| `ss -tulpn` | Shows listening and connected sockets. |
| `getent hosts <name>` | Checks name resolution using the system resolver. |
| `resolvectl status` | Shows DNS resolver state on systems using systemd-resolved. |

### GPU And NVIDIA

| Command | Use |
| --- | --- |
| `lspci -nnk -d 10de:` | Shows NVIDIA PCIe devices, vendor/device IDs, and kernel driver binding. |
| `nvidia-smi` | Shows NVIDIA driver, CUDA compatibility, GPU state, memory usage, temperature, power, and running processes. |
| `nvidia-smi -L` | Lists detected NVIDIA GPUs and UUIDs. |
| `nvidia-smi topo -m` | Shows GPU, CPU, and interconnect topology. |
| `nvidia-smi -q` | Provides detailed GPU query output. |
| `nvidia-smi -q -d ECC,PCI,POWER,TEMPERATURE,CLOCK` | Captures focused GPU health and telemetry domains where supported. |
| `nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_version,temperature.gpu,power.draw,power.limit,memory.total,memory.used,utilization.gpu,pstate --format=csv` | Captures compact GPU state for evidence bundles. |
| `nvidia-smi dmon` | Monitors GPU utilization, power, temperature, and clocks over time. |
| `nvidia-smi pmon` | Shows per-process GPU utilization. |
| `ls -l /dev/nvidia*` | Checks NVIDIA device nodes and permissions where present. |
| `lsmod \| grep nvidia` | Confirms whether NVIDIA kernel modules are loaded. |
| `modinfo nvidia` | Shows NVIDIA module metadata when available. |

### Thermal And Power

| Command | Use |
| --- | --- |
| `sensors` | Shows CPU, board, and fan sensor output when `lm-sensors` is configured. |
| `ipmitool sensor` | Shows BMC/IPMI sensor readings when available and permitted. |
| `nvidia-smi --query-gpu=temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.current.memory --format=csv` | Captures GPU temperature, power, limits, and clocks in a compact format. |
| `nvidia-smi --query-gpu=clocks_throttle_reasons.active,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown --format=csv` | Captures throttle-reason clues where supported. |
| `dmesg \| grep -i thermal` | Filters kernel messages for thermal events. |
| `ipmitool sel list` | Shows BMC system event log when available and permitted. |
| `ipmitool fru` | Shows field-replaceable unit data when available and permitted. |

### Drivers And Kernel Modules

| Command | Use |
| --- | --- |
| `lsmod` | Lists loaded kernel modules. |
| `modinfo <module>` | Shows module metadata such as version, filename, license, and supported aliases. |
| `dkms status` | Shows DKMS-built modules and their status across kernels. |
| `mokutil --sb-state` | Shows Secure Boot state if `mokutil` is installed. Useful for unsigned module issues. |
| `journalctl -k` | Reads kernel log messages from the systemd journal. |
| `ldconfig -p \| grep -Ei "cuda|nvidia"` | Shows visible runtime libraries on systems with `ldconfig`. |
| `dpkg -l \| grep -Ei "nvidia|cuda"` | Shows NVIDIA/CUDA packages on Debian/Ubuntu systems. |
| `rpm -qa \| grep -Ei "nvidia|cuda"` | Shows NVIDIA/CUDA packages on RHEL-like systems. |

## Failure Domain Notes

When symptoms appear, classify the likely failure domain before attempting remediation:

- Hardware visibility: device missing from PCIe, USB, or block inventory.
- Driver binding: hardware visible but no kernel module or wrong driver attached.
- Runtime/library: driver works, but CUDA, PyTorch, container runtime, or application stack cannot use the device.
- Thermal/power: device is present but throttles, resets, or shuts down under load.
- Storage/media: device reports I/O errors, health warnings, or filesystem problems.
- Networking/fabric: interface is missing, link is down, routing fails, DNS fails, or throughput is abnormal.
- Configuration/change event: issue started after kernel update, driver update, firmware change, reboot, workload change, or hardware maintenance.

## Safety Rules

- Do not reseat hardware unless authorized.
- Do not change BIOS, BMC, or firmware settings without approval.
- Do not run destructive disk tests on production systems.
- Do not install, remove, or downgrade drivers on shared systems without change approval.
- Preserve logs before rebooting when possible.
- Avoid stress tests unless the system owner approves the workload and risk.
- Clearly label assumptions and unknowns.
- Escalate with evidence when the next step would require physical intervention, firmware change, driver change, or destructive testing.

## Investigation Record Template

```text
Issue title:
Date/time:
System under test:
Expected behavior:
Actual behavior:
Recent changes:
Commands run:
Logs collected:
Telemetry collected:
Likely failure domain:
Safe remediation attempted:
Result:
Escalation needed:
Final outcome:
```
