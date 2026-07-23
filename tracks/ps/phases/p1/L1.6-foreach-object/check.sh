#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "squares.ps1" \
  "squares.ps1 — reference probe script must exist"

assert_output_contains "squares.ps1 outputs 1" "^1$" \
  "run: pwsh -File squares.ps1" \
  -- pwsh -NoProfile -NonInteractive -File squares.ps1

assert_output_contains "squares.ps1 outputs 4" "^4$" \
  "run: pwsh -File squares.ps1" \
  -- pwsh -NoProfile -NonInteractive -File squares.ps1

assert_output_contains "squares.ps1 outputs 9" "^9$" \
  "run: pwsh -File squares.ps1" \
  -- pwsh -NoProfile -NonInteractive -File squares.ps1

assert_file_exists "lengths.ps1" \
  "lengths.ps1 — reference probe script must exist"

assert_output_contains "lengths.ps1 outputs 1" "^1$" \
  "run: pwsh -File lengths.ps1" \
  -- pwsh -NoProfile -NonInteractive -File lengths.ps1

assert_output_contains "lengths.ps1 outputs 2" "^2$" \
  "run: pwsh -File lengths.ps1" \
  -- pwsh -NoProfile -NonInteractive -File lengths.ps1

assert_output_contains "lengths.ps1 outputs 3" "^3$" \
  "run: pwsh -File lengths.ps1" \
  -- pwsh -NoProfile -NonInteractive -File lengths.ps1

assert_file_contains "predictions.txt" '^squares=1 4 9$' \
  "predictions.txt — line squares=1 4 9"

assert_file_contains "predictions.txt" '^lengths=1 2 3$' \
  "predictions.txt — line lengths=1 2 3"

ck_summary
