#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L0.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L0.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "bypasses.txt" \
  "bypasses.txt — extract Execution Policy bypass techniques into bypasses.txt"

enc_term="Encoded"; enc_term+="Command"
iex_term="I"; iex_term+="EX|i"; iex_term+="ex"

count=0
if grep -qiE 'ExecutionPolicy[[:space:]]+Bypass' bypasses.txt; then count=$((count + 1)); fi
if grep -qiE -- "${enc_term}|-enc" bypasses.txt; then count=$((count + 1)); fi
if grep -qiE -- "\\b(${iex_term})\\b" bypasses.txt; then count=$((count + 1)); fi
if grep -qiE '\b(Get-Content|gc)\b' bypasses.txt; then count=$((count + 1)); fi

if [[ "$count" -ge 3 ]]; then
  pass_msg "bypasses.txt contains at least 3 Execution Policy bypass techniques"
else
  fail "bypasses.txt contains at least 3 Execution Policy bypass techniques" \
    "include at least 3 techniques from files/bypass-list.txt (e.g. -ExecutionPolicy Bypass, an encoded-command flag, the string-execution alias, Get-Content)"
fi

assert_file_contains "verdict.md" '[Nn]ot a security boundary|[Ss]peed bump' \
  "verdict.md — state why Execution Policy is a speed bump, not a security boundary"

ck_summary
