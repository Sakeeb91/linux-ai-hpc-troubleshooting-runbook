# Thermal Troubleshooting Workflow

Use this workflow when a system shows high temperature, clock throttling, fan or airflow concerns, power-limit behavior, thermal shutdown, or workload instability that may be temperature-related.

## Why Thermal Data Matters

AI/HPC systems often run sustained high-power workloads. Temperature and power data help distinguish normal transient spikes from cooling-margin problems, workload-induced throttling, system airflow issues, and hardware protection events.

## Symptoms Of Thermal Throttling

- Performance drops during sustained workload.
- GPU clocks fall while utilization remains high.
- Kernel logs mention thermal events, throttling, or shutdown.
- `nvidia-smi` shows high temperature or power-limit behavior.
- System becomes unstable only under sustained load.
- Fans or cooling system behave unexpectedly.

## Baseline Commands

```bash
nvidia-smi
nvidia-smi dmon
sensors
ipmitool sensor
journalctl -k | grep -i thermal
dmesg | grep -i thermal
```

Some tools may not be installed or may require permission. Record missing or denied commands.

## GPU Temperature Monitoring

Single snapshot:

```bash
nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.current.memory --format=csv
```

Short live sample:

```bash
nvidia-smi dmon -c 10
```

Capture both idle and workload readings if workload testing is authorized.

## Power Draw Monitoring

```bash
nvidia-smi --query-gpu=index,power.draw,power.limit,clocks.current.graphics,clocks.current.memory --format=csv
```

Interpretation:

- Power draw near limit can be normal under load.
- Low clocks with high utilization may indicate thermal, power, or application bottlenecks.
- Sudden power drops during load may indicate throttling, reset, or workload completion.

## Clock Throttling Clues

Record clocks with temperature and power together:

```bash
nvidia-smi --query-gpu=index,temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.current.memory,utilization.gpu --format=csv
nvidia-smi --query-gpu=index,clocks_throttle_reasons.active,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown,clocks_throttle_reasons.sw_power_cap --format=csv
```

Compare against expected behavior for the platform and workload. Do not assume a failure based only on one high reading.

Normal load heating usually has three properties: temperature rises, power draw rises, and then values stabilize while the workload continues. A failure pattern is more concerning when temperature continues climbing, clocks fall unexpectedly, throttle reasons activate, Xid events appear, or the workload crashes/resets.

## Fan And Cooling Checks

Safe checks:

- Look for obvious blocked airflow if physically present and authorized to inspect.
- Record BMC or IPMI fan sensor readings if available.
- Confirm the system is not placed in an unsuitable environment.
- Compare inlet, exhaust, CPU, board, and GPU sensors where available.

Avoid:

- Opening chassis, reseating parts, changing fan policies, or modifying BMC settings without approval.

## Airflow Obstruction

Potential clues:

- Multiple components show elevated temperature.
- Temperature rises faster than expected under modest load.
- BMC sensors report fan or inlet problems.
- The issue appears after physical move, rack change, filter change, or maintenance.

## Workload-Induced Thermal Rise

A temperature increase during load is expected. The question is whether it stabilizes within expected limits.

Collect:

- Idle baseline.
- Start time of workload.
- Temperature/power samples during workload.
- End time and cool-down behavior.
- Any throttle, reset, Xid, or shutdown messages.

## Short Spike Vs Sustained Thermal Issue

Short spike:

- Temperature rises briefly and returns to stable range.
- No repeated clock drop, reset, or thermal log event.
- Workload completes successfully.

Sustained issue:

- Temperature continues rising without stabilizing.
- Repeated throttling, clock drops, or power-limit behavior affects work.
- Kernel/BMC logs show thermal warnings or shutdown events.

## Pass, Warning, Fail Classification

- PASS: stable temperature within expected range during workload.
- WARNING: high but stable temperature, possible cooling margin issue.
- FAIL: thermal shutdown, repeated throttling, or uncontrolled temperature rise.

## Interview-Grade Interpretation

Do not claim a thermal failure from a single hot reading. Correlate:

- Ambient or inlet context where available.
- Idle baseline versus load baseline.
- Temperature trend over time.
- Power draw and power limit.
- Graphics/memory clocks.
- Throttle reason fields.
- Kernel/BMC/Xid events.
- Workload timing and whether the workload completed.

## Evidence To Attach

- Idle `nvidia-smi` output.
- Workload `nvidia-smi dmon` sample.
- Sensor output from `sensors` or `ipmitool sensor`.
- Thermal-related kernel logs.
- Workload name and timing.
- Physical inspection notes if authorized.
