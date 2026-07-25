#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "com-oneliners.txt" \
  "com-oneliners.txt — reference COM one-liners file must exist"

assert_file_exists "classify.txt" \
  "classify.txt — record COM classification analysis in classify.txt"

assert_file_contains_fixed "classify.txt" "WScript.Shell" \
  "classify.txt — must mention WScript.Shell"

assert_file_contains_fixed "classify.txt" "Shell.Application" \
  "classify.txt — must mention Shell.Application"

assert_file_contains "classify.txt" '[Ee]xecut(e|es|ing|ion)|[Rr]un' \
  "classify.txt — must mention Execution or Run"

assert_file_contains "classify.txt" '[Pp]ersist|[Rr]egistry' \
  "classify.txt — must mention Persistence or Registry"

ck_summary
