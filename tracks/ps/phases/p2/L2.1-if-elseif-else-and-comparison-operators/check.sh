#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "caseq.ps1" \
  "caseq.ps1 — reference probe script must exist"

assert_output_contains "-ceq differs on case mismatch" "ceq-differs" \
  "run: pwsh -File caseq.ps1" \
  -- pwsh -NoProfile -NonInteractive -File caseq.ps1

assert_output_contains "-eq matches case-insensitively" "eq-MATCH" \
  "run: pwsh -File caseq.ps1" \
  -- pwsh -NoProfile -NonInteractive -File caseq.ps1

assert_file_exists "match.ps1" \
  "match.ps1 — reference probe script must exist"

assert_output_contains "-match fills \$Matches" "2026" \
  "run: pwsh -File match.ps1" \
  -- pwsh -NoProfile -NonInteractive -File match.ps1

assert_file_exists "verdict.txt" \
  "verdict.txt — explain array filtering behavior in verdict.txt"

assert_file_contains "verdict.txt" '[Aa]rray' \
  "verdict.txt — must mention array"

assert_file_contains "verdict.txt" '[Ff]ilter' \
  "verdict.txt — must mention filter"

ck_summary
