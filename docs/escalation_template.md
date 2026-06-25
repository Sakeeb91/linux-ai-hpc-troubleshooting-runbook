# Escalation Template

Use this template when escalating an unresolved issue to internal engineering, vendor support, or a hardware owner.

## Short Summary

One or two sentences describing the issue, affected system, and current status.

## Business/Customer Impact

- Affected user, customer, lab, or workflow:
- Impact:
- Duration:
- Workaround available:
- Delivery/validation milestone blocked:
- Number of systems affected:

## System Details

- Hostname:
- Server model:
- CPU:
- GPU:
- RAM:
- Storage:
- NIC/fabric:
- Location/rack, if applicable:

## Hardware/Software Versions

- OS version:
- Kernel version:
- NVIDIA driver version:
- CUDA version:
- BIOS firmware:
- BMC firmware:
- Container runtime:
- Relevant application or workload version:

## Reproduction Steps

1. 
2. 
3. 

## Evidence Collected

- Diagnostic output directory:
- Output file index:
- Kernel log excerpts:
- `nvidia-smi` output:
- `lspci -nnk` or PCIe inventory:
- Thermal/power telemetry:
- Storage health:
- Network state:
- Screenshots or ticket links:

## What Has Already Been Tried

List approved actions taken so far. Include commands, timestamps, and results.

## Support Needed

Describe the decision, access, replacement part, firmware guidance, driver guidance, or deeper engineering analysis needed.

Be explicit about the requested decision:

- Approve driver or DKMS repair.
- Approve reboot or maintenance window.
- Confirm expected hardware configuration.
- Confirm firmware/BIOS/BMC guidance.
- Dispatch hardware service or replacement.
- Provide vendor interpretation of logs.

## Urgency

- Severity:
- Required response time:
- Deadline or customer commitment:
- Risk if unresolved:

## Attachments

- 
- 
- 
