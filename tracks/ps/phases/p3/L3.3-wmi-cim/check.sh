#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "wmi-gone.ps1" \
  "wmi-gone.ps1 — reference probe script must exist"

assert_output_contains "Get-WmiObject is removed in PS7" "ABSENT-IN-PS7" \
  "run: pwsh -File wmi-gone.ps1" \
  -- pwsh -NoProfile -NonInteractive -File wmi-gone.ps1

assert_file_exists "notes.txt" \
  "notes.txt — record WMI analysis in notes.txt"

assert_file_contains_fixed "notes.txt" "Get-CimInstance" \
  "notes.txt — must mention Get-CimInstance"

assert_file_contains "notes.txt" '[Pp]ersist' \
  "notes.txt — must mention Persistence"

assert_file_contains "notes.txt" '[Ee]xecut' \
  "notes.txt — must mention Execution"

ck_summary
