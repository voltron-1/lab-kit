#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "evens.ps1" \
  "evens.ps1 — reference probe script must exist"

assert_output_contains "evens.ps1 outputs 2" "^2$" \
  "run: pwsh -File evens.ps1" \
  -- pwsh -NoProfile -NonInteractive -File evens.ps1

assert_output_contains "evens.ps1 outputs 4" "^4$" \
  "run: pwsh -File evens.ps1" \
  -- pwsh -NoProfile -NonInteractive -File evens.ps1

assert_output_contains "evens.ps1 outputs 6" "^6$" \
  "run: pwsh -File evens.ps1" \
  -- pwsh -NoProfile -NonInteractive -File evens.ps1

assert_output_contains "evens.ps1 outputs 8" "^8$" \
  "run: pwsh -File evens.ps1" \
  -- pwsh -NoProfile -NonInteractive -File evens.ps1

assert_output_contains "evens.ps1 outputs 10" "^10$" \
  "run: pwsh -File evens.ps1" \
  -- pwsh -NoProfile -NonInteractive -File evens.ps1

assert_file_contains "predictions.txt" '^numbers=2 4 6 8 10$' \
  "predictions.txt — line numbers=2 4 6 8 10"

assert_file_contains "predictions.txt" '^type_preserved=yes$' \
  "predictions.txt — line type_preserved=yes"

ck_summary
