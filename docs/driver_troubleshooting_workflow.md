# Driver Troubleshooting Workflow

Use this workflow when NVIDIA GPU hardware is visible but the driver, CUDA runtime, framework, or container cannot use it correctly.

## First Rule

Do not install, remove, downgrade, or rebuild drivers on shared systems unless change approval exists. Preserve logs first, then escalate if the next step changes system state.

## Baseline Commands

```bash
nvidia-smi
nvcc --version
python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
dkms status
lsmod | grep nvidia
modinfo nvidia
journalctl -k | grep -i nvidia
mokutil --sb-state
ldconfig -p | grep -Ei "cuda|nvidia"
dpkg -l | grep -Ei "nvidia|cuda"
rpm -qa | grep -Ei "nvidia|cuda"
```

Some commands may not be installed. Record missing commands as part of the environment.

## Driver Not Installed

Symptoms:

- `nvidia-smi: command not found`
- GPU visible in `lspci`, but no NVIDIA modules in `lsmod`
- Package inventory shows no NVIDIA driver package

Evidence:

```bash
lspci | grep -i nvidia
lsmod | grep nvidia
which nvidia-smi
journalctl -k | grep -i nvidia
```

Next action:

- Confirm expected driver version from owner or vendor guidance.
- Escalate for driver installation approval.
- Do not install ad hoc drivers on production or shared systems.

## Driver Loaded But `nvidia-smi` Fails

Symptoms:

- NVIDIA modules are loaded.
- `nvidia-smi` returns a driver/library mismatch or cannot communicate with the driver.

Evidence:

```bash
nvidia-smi
lsmod | grep nvidia
modinfo nvidia
journalctl -k | grep -i nvidia
dmesg | grep -Ei "nvidia|xid|error|fail"
```

Likely causes:

- User-space library and kernel module version mismatch.
- GPU error state.
- Incomplete driver upgrade.
- Kernel update changed module compatibility.

Next action:

- Capture exact error text.
- Compare installed package version with module version.
- Escalate if remediation requires restart, driver reinstall, or service disruption.

## CUDA Runtime Mismatch

Symptoms:

- `nvidia-smi` works, but CUDA application fails.
- Application reports unsupported CUDA version or missing CUDA libraries.

Evidence:

```bash
nvidia-smi
nvcc --version
python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
echo "$PATH"
echo "$LD_LIBRARY_PATH"
ldconfig -p | grep -Ei "cuda|nvidia"
```

Interpretation:

- `nvidia-smi` reports driver-supported CUDA compatibility, not necessarily the installed toolkit used by an application.
- Framework wheels may bundle specific CUDA runtime versions.
- Multiple Python environments can hide the actual runtime in use.

## PyTorch Cannot See CUDA

Symptoms:

- `nvidia-smi` works.
- PyTorch reports `torch.cuda.is_available()` as `False`.

Commands:

```bash
python -c "import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.device_count())"
which python
python -m pip show torch
```

Likely causes:

- CPU-only PyTorch package.
- Wrong virtual environment.
- CUDA runtime mismatch.
- Container does not expose GPU devices.
- Permissions or environment variables hide devices.

## Secure Boot Module Signing Issues

Symptoms:

- NVIDIA module build exists but will not load.
- Kernel logs mention signature, key, or verification failure.

Commands:

```bash
mokutil --sb-state
journalctl -k | grep -Ei "nvidia|module|signature|secure"
dkms status
```

Next action:

- Record Secure Boot state.
- Escalate for approved module signing, Secure Boot policy, or driver process.
- Do not disable Secure Boot as a troubleshooting shortcut on managed systems.

## DKMS Build Failure

Symptoms:

- Driver worked before kernel update.
- `dkms status` shows build failure or module not installed for current kernel.

Commands:

```bash
uname -r
dkms status
journalctl -k | grep -i nvidia
ls /usr/src | grep -Ei "nvidia|linux"
```

Next action:

- Capture current kernel and DKMS state.
- Escalate for approved rebuild, package repair, or kernel rollback decision.

## Kernel Update Broke Driver

Symptoms:

- Issue started after reboot or kernel update.
- Driver module is missing for current kernel.
- Previous kernel may still have a working module.

Commands:

```bash
uname -a
dkms status
lsmod | grep nvidia
journalctl -k | grep -Ei "nvidia|dkms|module|error|fail"
```

Next action:

- Document recent change timing.
- Do not reboot into alternate kernels or change boot config without approval.

## Container Cannot Access GPU

Symptoms:

- `nvidia-smi` works on host.
- `nvidia-smi` fails inside container.
- Framework sees no GPU inside container.

Evidence:

```bash
nvidia-smi
docker --version
docker info
nvidia-container-cli info
```

Collect the container launch command, image name, runtime settings, and exact error. This often points to missing NVIDIA container runtime configuration, missing device exposure, or image/runtime mismatch.

If Docker is approved on the system, a common validation pattern is to run an NVIDIA CUDA container with `--gpus all`. Treat this as an optional runtime test because it may pull images, use network access, and run workload code.

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## NVIDIA Persistence Mode Basics

Persistence mode can reduce GPU initialization overhead and keep driver state active on supported systems. It changes system behavior, so treat it as a configuration decision rather than a casual troubleshooting command.

Safe check:

```bash
nvidia-smi -q | grep -i "persistence"
```

Do not enable or disable persistence mode on shared systems without approval.

## When To Escalate Instead Of Changing Drivers

Escalate when:

- The system is shared, production-like, or customer-facing.
- Remediation requires reboot, driver installation, package removal, kernel changes, or Secure Boot changes.
- GPU is missing from PCIe inventory.
- Kernel logs show repeated Xid, PCIe, thermal, or power events.
- The expected driver/CUDA version is unclear.
- The issue follows firmware, BIOS, BMC, kernel, or hardware maintenance.
- Vendor or customer support will need a reproducible evidence bundle before approving changes.
