#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "reg-oneliners.txt" \
  "reg-oneliners.txt — reference registry one-liners file must exist"

assert_file_exists "persistence.txt" \
  "persistence.txt — record persistence analysis in persistence.txt"

assert_file_contains_fixed "persistence.txt" 'CurrentVersion\Run' \
  "persistence.txt — must mention CurrentVersion\\Run"

assert_file_contains "persistence.txt" '[Pp]ersist|[Aa]utostart|T1547' \
  "persistence.txt — must mention Persistence, Autostart, or T1547"

ck_summary
