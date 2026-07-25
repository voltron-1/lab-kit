#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "AdminTools.psd1" \
  "AdminTools.psd1 — reference module manifest must exist"

assert_file_exists "AdminTools.psm1" \
  "AdminTools.psm1 — reference module code file must exist"

assert_file_exists "readmanifest.ps1" \
  "readmanifest.ps1 — reference probe script must exist"

assert_output_contains "manifest exports Get-DiskReport" "Get-DiskReport" \
  "run: pwsh -File readmanifest.ps1" \
  -- pwsh -NoProfile -NonInteractive -File readmanifest.ps1

assert_output_contains "manifest exports Restart-AppPool" "Restart-AppPool" \
  "run: pwsh -File readmanifest.ps1" \
  -- pwsh -NoProfile -NonInteractive -File readmanifest.ps1

assert_output_contains "manifest reports version 1.2.0" "1.2.0" \
  "run: pwsh -File readmanifest.ps1" \
  -- pwsh -NoProfile -NonInteractive -File readmanifest.ps1

assert_file_exists "notes.txt" \
  "notes.txt — record manifest analysis in notes.txt"

assert_file_contains_fixed "notes.txt" ".psm1" \
  "notes.txt — must mention .psm1"

assert_file_contains_fixed "notes.txt" "RootModule" \
  "notes.txt — must mention RootModule"

assert_file_contains "notes.txt" '[Mm]anifest' \
  "notes.txt — must mention manifest"

ck_summary
