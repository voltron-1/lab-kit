#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "expand.ps1" \
  "expand.ps1 — reference probe script must exist"

assert_output_contains "ExpandProperty unwraps to a bare Int32 value" '^[0-9]+$' \
  "run: pwsh -File expand.ps1" \
  -- pwsh -NoProfile -NonInteractive -File expand.ps1

assert_file_exists "itype.ps1" \
  "itype.ps1 — reference probe script must exist"

assert_output_contains "ExpandProperty type is Int32" "Int32" \
  "run: pwsh -File itype.ps1" \
  -- pwsh -NoProfile -NonInteractive -File itype.ps1

assert_file_exists "calc.ps1" \
  "calc.ps1 — reference probe script must exist"

assert_output_contains "calculated property adds an MB column" "MB" \
  "run: pwsh -File calc.ps1" \
  -- pwsh -NoProfile -NonInteractive -File calc.ps1

assert_file_exists "seltype.ps1" \
  "seltype.ps1 — reference probe script must exist"

assert_output_contains "projection type is PSCustomObject" "PSCustomObject" \
  "run: pwsh -File seltype.ps1" \
  -- pwsh -NoProfile -NonInteractive -File seltype.ps1

assert_file_contains "predictions.txt" '^expand_type=Int32$' \
  "predictions.txt — line expand_type=Int32"

assert_file_contains "predictions.txt" '^select_type=PSCustomObject$' \
  "predictions.txt — line select_type=PSCustomObject"

assert_file_contains "predictions.txt" '^calc_column=MB$' \
  "predictions.txt — line calc_column=MB"

ck_summary
