#!/usr/bin/env bash
set -u

failures=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$*"
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "found $path"
  else
    fail "missing $path"
  fi
}

required_files=(
  README.md
  LICENSE
  docs/linux_hardware_troubleshooting_runbook.md
  docs/gpu_detection_workflow.md
  docs/driver_troubleshooting_workflow.md
  docs/thermal_troubleshooting_workflow.md
  docs/storage_troubleshooting_workflow.md
  docs/networking_troubleshooting_workflow.md
  docs/memory_cpu_troubleshooting_workflow.md
  docs/validation_checklist.md
  docs/issue_report_template.md
  docs/escalation_template.md
  docs/glossary.md
  scripts/collect_system_inventory.sh
  scripts/collect_gpu_diagnostics.sh
  scripts/collect_storage_diagnostics.sh
  scripts/collect_network_diagnostics.sh
  scripts/collect_thermal_diagnostics.sh
  scripts/collect_kernel_logs.sh
  scripts/run_full_diagnostic_collection.sh
  scripts/validate_project.sh
  examples/sample_system_inventory.txt
  examples/sample_gpu_diagnostics.txt
  examples/sample_kernel_log_excerpt.txt
  examples/sample_issue_report.md
  examples/sample_escalation_note.md
)

for path in "${required_files[@]}"; do
  check_file "$path"
done

for script in scripts/*.sh; do
  if bash -n "$script"; then
    pass "syntax ok: $script"
  else
    fail "syntax failed: $script"
  fi

  if [[ -x "$script" ]]; then
    pass "executable: $script"
  else
    fail "not executable: $script"
  fi
done

if find scripts -name '*.sh' ! -name 'validate_project.sh' -print0 \
  | xargs -0 grep -InE '\b(mkfs|badblocks|shutdown|poweroff|reboot|parted|fdisk|sgdisk)\b|rm -rf|dd if='; then
  fail 'potential destructive command found in scripts'
else
  pass 'no obvious destructive commands found in scripts'
fi

if git check-ignore -q outputs/smoke-test-output.txt; then
  pass 'generated outputs are ignored by git'
else
  fail 'outputs/ generated files are not ignored by git'
fi

if [[ "$failures" -eq 0 ]]; then
  printf 'Project validation passed.\n'
  exit 0
fi

printf 'Project validation failed with %d issue(s).\n' "$failures" >&2
exit 1
