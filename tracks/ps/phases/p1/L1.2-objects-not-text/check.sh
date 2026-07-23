#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "type.ps1" \
  "type.ps1 — reference probe script must exist"

assert_output_contains "Get-Process emits Process objects" "System.Diagnostics.Process" \
  "run: pwsh -File type.ps1" \
  -- pwsh -NoProfile -NonInteractive -File type.ps1

assert_file_exists "prediction.txt" \
  "prediction.txt — write System.Diagnostics.Process into prediction.txt"

assert_file_contains_fixed "prediction.txt" "System.Diagnostics.Process" \
  "prediction.txt — must contain exact type System.Diagnostics.Process"

ck_summary
