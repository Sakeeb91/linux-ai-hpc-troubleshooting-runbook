# GPU Detection Workflow

Use this workflow when an NVIDIA GPU is expected but the operating system, driver, CUDA runtime, or application cannot use it.

## Goal

Determine whether the issue is hardware visibility, driver loading, runtime/library mismatch, permissions, container access, thermal/power protection, or a GPU error state.

## Expected Inputs

Before running commands, write down:

- Expected GPU count and model, if known.
- Whether this is host Linux, a VM, a container, or a Kubernetes job.
- Recent changes such as kernel update, driver update, firmware update, physical service, or workload change.
- Whether GPUs are expected to be dedicated, shared, MIG-partitioned, or hidden by `CUDA_VISIBLE_DEVICES`.

## Step 1: Confirm OS Sees PCIe GPU

```bash
lspci | grep -i nvidia
lspci -nnk -d 10de:
lspci -tv
```

Expected result: one line per NVIDIA PCIe device, or multiple lines per GPU depending on the platform.

If nothing appears:

- Confirm expected GPU count from the system record.
- Check whether the device appears with a different vendor string.
- Review kernel logs for PCIe errors.
- Escalate before physical reseating or BIOS/BMC changes.

## Step 2: Confirm NVIDIA Driver Is Loaded

```bash
lsmod | grep nvidia
modinfo nvidia
ls -l /dev/nvidia*
```

Expected result: loaded NVIDIA-related modules such as `nvidia`, `nvidia_uvm`, `nvidia_drm`, or `nvidia_modeset`.

If no module appears:

- Check whether a driver is installed.
- Check kernel logs for module load errors.
- Check Secure Boot state where relevant.
- Avoid installing or changing drivers on shared systems without approval.

## Step 3: Confirm `nvidia-smi` Works

```bash
nvidia-smi
nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_version,temperature.gpu,power.draw,power.limit,memory.total,memory.used,utilization.gpu,pstate --format=csv
nvidia-smi -q -d ECC,PCI,POWER,TEMPERATURE,CLOCK
```

Expected result: GPU table with driver version, CUDA compatibility, temperature, power, memory, and process information.

Capture the exact error if it fails. Common categories include:

- Driver not loaded.
- Driver/library mismatch.
- No devices found.
- Permission problem.
- GPU in error state.

## Step 4: Confirm GPU Count

```bash
nvidia-smi -L
```

Compare the detected count with the expected hardware inventory. Record GPU UUIDs if available.

## Step 5: Confirm PyTorch CUDA Availability

```bash
python -c "import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.device_count())"
echo "$CUDA_VISIBLE_DEVICES"
```

Interpretation:

- `True` and expected count: framework can see CUDA devices.
- `False` with working `nvidia-smi`: likely CUDA runtime, PyTorch build, environment, or container issue.
- Import error: PyTorch is not installed in the current Python environment.

## Step 6: Check Topology

```bash
nvidia-smi topo -m
```

Capture GPU, CPU, and interconnect topology where supported. This is useful for multi-GPU validation and for checking whether the layout matches expectations.

For multi-GPU systems, record whether topology is consistent with the platform expectation. Do not claim NVLink, NVSwitch, PCIe switch, or fabric behavior unless the evidence explicitly shows it.

## Step 7: Check Logs

```bash
dmesg | grep -i nvidia
journalctl -k | grep -i nvidia
```

Also consider PCIe and general error filters:

```bash
dmesg | grep -Ei "nvidia|pcie|xid|error|fail"
journalctl -k | grep -Ei "nvidia|pcie|xid|error|fail"
```

## Step 8: Identify Failure Domain

| Symptom | Likely domain | Evidence to collect |
| --- | --- | --- |
| GPU missing from `lspci` | Hardware visibility, PCIe, BIOS, riser, power, slot, or platform config | `lspci`, `dmesg`, expected inventory, recent maintenance notes |
| GPU visible in `lspci`, no NVIDIA module | Driver missing, DKMS failure, Secure Boot, kernel mismatch | `lsmod`, `dkms status`, `mokutil --sb-state`, `journalctl -k` |
| NVIDIA module loaded, `nvidia-smi` fails | Driver/library mismatch, device error, permissions | exact `nvidia-smi` error, `modinfo nvidia`, package versions, logs |
| `nvidia-smi` sees fewer GPUs than expected | MIG/visibility setting, failed GPU, driver issue, platform inventory mismatch | `nvidia-smi -L`, `CUDA_VISIBLE_DEVICES`, topology, expected inventory |
| `nvidia-smi` works, PyTorch CUDA false | Runtime/library mismatch, Python environment, container issue | PyTorch version, `torch.version.cuda`, environment, container runtime config |
| GPU appears then disappears or resets | GPU error state, PCIe instability, thermal/power event | Xid logs, PCIe logs, temperature, power, workload timeline |
| Works on host but not container | Container runtime, device permissions, missing NVIDIA container toolkit | container command, runtime config, device mounts, `nvidia-smi` inside container |

## Text Decision Tree

```text
Start
|
+-- Does lspci show NVIDIA hardware?
|   |
|   +-- No -> Hardware visibility domain.
|   |        Collect PCIe logs, expected inventory, recent change history.
|   |        Escalate before physical or firmware changes.
|   |
|   +-- Yes
|       |
|       +-- Is NVIDIA driver module loaded?
|           |
|           +-- No -> Driver/kernel module domain.
|           |        Check DKMS, Secure Boot, kernel version, module logs.
|           |
|           +-- Yes
|               |
|               +-- Does nvidia-smi work?
|                   |
|                   +-- No -> Driver/library/device error domain.
|                   |        Capture exact error, modinfo, logs, Xid events.
|                   |
|                   +-- Yes
|                       |
|                       +-- Does framework see CUDA?
|                           |
|                           +-- No -> Runtime/environment/container domain.
|                           |        Check PyTorch build, CUDA runtime, env, container.
|                           |
|                           +-- Yes -> GPU detection passes.
|                                    Continue with workload, topology, thermal checks.
```

## Evidence To Attach

- `lspci | grep -i nvidia`
- `lsmod | grep nvidia`
- `nvidia-smi`
- `nvidia-smi -L`
- `nvidia-smi topo -m`
- compact `nvidia-smi --query-gpu` CSV
- PyTorch CUDA check output
- `CUDA_VISIBLE_DEVICES`
- `/dev/nvidia*` permissions where present
- NVIDIA and PCIe-related kernel logs
- Expected GPU count and server inventory
