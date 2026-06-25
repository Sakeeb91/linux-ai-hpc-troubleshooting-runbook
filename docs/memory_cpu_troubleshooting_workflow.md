# CPU And Memory Troubleshooting Workflow

Use this workflow for high CPU utilization, memory exhaustion, swap usage, NUMA awareness, ECC memory clues, and process-level diagnosis.

## Baseline Commands

```bash
lscpu
free -h
top
htop
vmstat
numactl --hardware
dmidecode -t memory
dmesg | grep -i memory
journalctl -k | grep -i error
```

Some commands may not be installed or may require permission.

## High CPU Utilization

Symptoms:

- Load average is high.
- Workload is slow or unresponsive.
- One process consumes most CPU.
- System feels overloaded during validation.

Commands:

```bash
uptime
top
lscpu
```

If installed:

```bash
mpstat -P ALL 1 5
```

Interpretation:

- Compare load average with CPU core/thread count.
- Identify whether one process, many processes, or kernel/system activity is driving load.
- Record workload timing and recent changes.

## Memory Exhaustion

Symptoms:

- Application killed unexpectedly.
- Kernel logs mention OOM.
- `free -h` shows little available memory.
- Swap usage grows.

Commands:

```bash
free -h
cat /proc/meminfo
top
dmesg | grep -Ei "out of memory|oom|killed process|memory"
journalctl -k | grep -Ei "out of memory|oom|killed process|memory"
```

Next action:

- Record process memory usage and workload context.
- Escalate before changing memory limits, swap, kernel parameters, or workload configuration.

## Swap Usage

Commands:

```bash
free -h
swapon --show
vmstat 1 5
```

Interpretation:

- Some swap usage is not automatically a failure.
- Active swapping during workload can explain severe slowdown.
- Correlate swap activity with process memory growth.

## NUMA Awareness

NUMA matters when CPU sockets and memory locality affect performance, especially on multi-socket systems with GPUs or high-speed NICs.

Commands:

```bash
lscpu
numactl --hardware
```

Record NUMA nodes and CPU layout. Do not change CPU affinity, memory policy, or workload placement without understanding the application and system owner expectations.

## ECC Memory Errors

ECC memory can correct certain errors. Corrected errors may be warnings; repeated corrected errors or uncorrected errors can indicate hardware risk.

Commands:

```bash
dmesg | grep -Ei "edac|ecc|mce|memory error|hardware error"
journalctl -k | grep -Ei "edac|ecc|mce|memory error|hardware error"
```

Next action:

- Preserve logs with timestamps.
- Escalate repeated corrected errors, uncorrected errors, or machine-check events.
- Do not reseat DIMMs unless authorized.

## Process-Level Diagnosis

Commands:

```bash
top
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

Record:

- Process name and PID.
- User.
- CPU and memory percentage.
- Workload or service owner.
- Whether behavior started after a change.

## Evidence To Attach

- `lscpu`
- `free -h`
- `vmstat`
- `top` or process snapshot
- `numactl --hardware`, if available
- `dmidecode -t memory`, if available and permitted
- Kernel logs for OOM, ECC, MCE, or hardware errors
