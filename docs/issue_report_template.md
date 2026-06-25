# Issue Report Template

## Issue Title

`Short, specific title`

## Date/Time

`YYYY-MM-DD HH:MM timezone`

## Reporter

`Name / team / contact`

## System Under Test

- Hostname:
- Server model:
- CPU:
- GPU:
- RAM:
- Storage:
- Network:
- Location/rack, if applicable:

## Environment

- OS version:
- Kernel version:
- NVIDIA driver version:
- CUDA version:
- BIOS/BMC firmware version, if available:
- Container runtime, if relevant:
- Workload or test name:

## Severity

- Severity:
- Impact:
- Scope:
- Customer or validation milestone affected:
- Workaround available:
- Time first observed:
- Last known good state:

## Summary

Briefly describe the issue in one or two paragraphs.

State the likely failure domain only if evidence supports it. Avoid guessing beyond the logs and telemetry.

## Expected Behavior

Describe what should have happened.

## Actual Behavior

Describe what happened, including exact error text where possible.

## Steps To Reproduce

1. 
2. 
3. 

## Expected Configuration

- Expected GPU count/model:
- Expected NIC/fabric:
- Expected storage layout:
- Expected driver/CUDA version:
- Expected workload/test:

## Commands Run

```bash
# Paste commands here
```

## Relevant Logs

```text
# Paste relevant excerpts here
```

## Telemetry Observed

- Temperature:
- Power draw:
- GPU utilization:
- CPU load:
- Memory usage:
- Storage state:
- Network state:

## Suspected Failure Domain

- [ ] Hardware visibility
- [ ] Driver/kernel module
- [ ] CUDA/runtime/library
- [ ] Container/permissions
- [ ] Thermal/power
- [ ] Storage
- [ ] Networking
- [ ] Configuration/change event
- [ ] Unknown

## Attempted Remediation

List only approved, safe actions already taken.

## Stop Condition Reached

Explain why this is being escalated instead of continuing locally, such as driver change required, physical service required, firmware decision required, destructive storage action required, or customer-impacting reboot required.

## Current Status

Open / mitigated / resolved / monitoring / escalated.

## Recommended Next Action

Describe the next concrete step and who should own it.

## Attachments/Evidence

- Diagnostic output directory:
- Output file index:
- Screenshots:
- Logs:
- Ticket links:
- Vendor references:
