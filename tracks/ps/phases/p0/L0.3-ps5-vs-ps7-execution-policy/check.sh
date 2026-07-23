#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L0.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L0.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "bypasses.txt" \
  "bypasses.txt — extract Execution Policy bypass techniques into bypasses.txt"

count=0
if grep -qiE 'ExecutionPolicy[[:space:]]+Bypass' bypasses.txt; then count=$((count + 1)); fi
if grep -qiE 'EncodedCommand|-enc' bypasses.txt; then count=$((count + 1)); fi
if grep -qiE '\b(IEX|iex)\b' bypasses.txt; then count=$((count + 1)); fi
if grep -qiE '\b(Get-Content|gc)\b' bypasses.txt; then count=$((count + 1)); fi

if [[ "$count" -ge 3 ]]; then
  pass_msg "bypasses.txt contains at least 3 Execution Policy bypass techniques"
else
  fail "bypasses.txt contains at least 3 Execution Policy bypass techniques" \
    "include at least 3 techniques from files/bypass-list.txt (e.g. -ExecutionPolicy Bypass, -EncodedCommand, IEX, Get-Content)"
fi

assert_file_contains "verdict.md" '[Nn]ot a security boundary|[Ss]peed bump' \
  "verdict.md — state why Execution Policy is a speed bump, not a security boundary"

ck_summary
