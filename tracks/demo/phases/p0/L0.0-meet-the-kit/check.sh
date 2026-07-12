#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check demo L0.0}"
: "${LAB_CHECKLIB:?run this via: lab check demo L0.0}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "fixed.conf" "step 2 — create it: cp broken.conf fixed.conf"
assert_file_contains_fixed "fixed.conf" "max_retries = 3" \
  "step 2 — fix the line 'max_retries = ten' in fixed.conf"
assert_file_contains_fixed "fixed.conf" "workspace_fence = on" \
  "step 2 — flip workspace_fence to on in fixed.conf"
assert_output_contains "sysinfo.txt has a kernel version" '^[0-9]+\.[0-9]+' \
  "step 3 — run: uname -r > sysinfo.txt (inside the workspace)" -- cat sysinfo.txt
location_hint="step 4 — run: pwd > location.txt while inside workspace/demo/L0.0"
if [[ -f location.txt ]]; then
  recorded_dir="$(realpath -m -- "$(cat location.txt)")"
  workspace_dir="$(realpath -- "$LAB_WORKSPACE")"
  if [[ "$recorded_dir" == "$workspace_dir" ]]; then
    pass_msg "location.txt was written from inside the workspace"
  else
    fail "location.txt was written from inside the workspace" "$location_hint"
  fi
else
  fail "location.txt missing" "$location_hint"
fi

ck_summary
