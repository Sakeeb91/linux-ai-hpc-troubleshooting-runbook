# Storage Troubleshooting Workflow

Use this workflow for disk not detected, disk full, slow I/O, filesystem errors, NVMe health concerns, and mount issues.

## First Rule

Start with non-destructive checks. Do not run destructive disk tests, repartition, reformat, repair filesystems, or reset controllers on shared systems without approval and backups.

## Baseline Commands

```bash
lsblk
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
df -h
findmnt
mount
blkid
dmesg | grep -i error
smartctl -a /dev/sdX
nvme list
nvme smart-log /dev/nvme0
iostat -xz 1 5
cat /proc/mdstat
```

Use device names carefully. Replace `/dev/sdX` and `/dev/nvme0` only after confirming the device.

## Disk Not Detected

Symptoms:

- Expected disk is missing from `lsblk`.
- NVMe device absent from `nvme list`.
- Storage controller appears but target disk is missing.

Evidence:

```bash
lsblk
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
lspci
nvme list
dmesg | grep -Ei "nvme|disk|ata|scsi|error|fail"
```

Next action:

- Compare against expected inventory.
- Check recent maintenance or configuration changes.
- Escalate before reseating hardware, changing BIOS settings, or replacing parts.

## Disk Full

Symptoms:

- Application failures due to no space left.
- `df -h` shows high usage.
- Logs or outputs cannot be written.

Commands:

```bash
df -h
lsblk
mount
```

Next action:

- Identify affected filesystem.
- Preserve logs if possible.
- Escalate cleanup decisions to the system owner if data ownership is unclear.

## Slow I/O

Symptoms:

- Workload stalls on reads/writes.
- High I/O wait.
- Storage-related timeout messages.

Evidence:

```bash
lsblk
df -h
dmesg | grep -Ei "i/o|timeout|reset|nvme|disk|error|fail"
nvme list
```

If installed, performance tools such as `iostat` can help, but avoid installing tools on controlled systems without approval.

```bash
iostat -xz 1 5
vmstat 1 5
```

Focus on evidence such as high `%util`, high await time, queueing, timeouts, controller resets, or filesystem errors. Do not benchmark with write-heavy tools unless explicitly approved.

## Filesystem Errors

Symptoms:

- Kernel logs show filesystem errors.
- Mount becomes read-only.
- Application reports I/O or metadata errors.

Evidence:

```bash
mount
df -h
dmesg | grep -Ei "ext4|xfs|btrfs|filesystem|read-only|error"
journalctl -k | grep -Ei "filesystem|read-only|error"
```

Next action:

- Do not run `fsck` or repair commands on mounted production filesystems without approval.
- Escalate with logs, affected mount point, and workload impact.

## NVMe Health

Commands:

```bash
nvme list
nvme smart-log /dev/nvme0
```

Review:

- Critical warnings.
- Temperature.
- Media and data integrity errors.
- Available spare.
- Percentage used.

If health data indicates risk, escalate before heavy testing.

## Mount Issues

Symptoms:

- Expected filesystem not mounted.
- Mount command fails.
- Device exists but mount point is empty or incorrect.

Evidence:

```bash
lsblk
blkid
findmnt
mount
cat /etc/fstab
dmesg | grep -Ei "mount|filesystem|uuid|error|fail"
```

Do not edit `/etc/fstab` or change mount options without owner approval.

## Log Collection

Storage log filters:

```bash
dmesg | grep -Ei "nvme|disk|sda|sdb|scsi|ata|i/o|filesystem|ext4|xfs|btrfs|error|fail"
journalctl -k | grep -Ei "nvme|disk|scsi|ata|i/o|filesystem|error|fail"
```

## Evidence To Attach

- `lsblk`
- `df -h`
- `mount`
- `blkid`
- `nvme list`, if available
- SMART or NVMe health output, if available
- `iostat` or `vmstat` output, if available
- Relevant kernel logs
- Expected storage configuration
