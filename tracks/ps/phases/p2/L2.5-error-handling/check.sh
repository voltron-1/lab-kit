#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "catch.ps1" \
  "catch.ps1 — reference probe script must exist"

assert_output_contains "-EA Stop makes the error catchable" "CAUGHT" \
  "run: pwsh -File catch.ps1" \
  -- pwsh -NoProfile -NonInteractive -File catch.ps1

assert_output_contains "finally block always runs" "FINALLY" \
  "run: pwsh -File catch.ps1" \
  -- pwsh -NoProfile -NonInteractive -File catch.ps1

assert_file_exists "nocatch.ps1" \
  "nocatch.ps1 — reference probe script must exist"

assert_output_contains "non-terminating error is not caught; execution reaches end" "REACHED-END" \
  "run: pwsh -File nocatch.ps1" \
  -- pwsh -NoProfile -NonInteractive -File nocatch.ps1

assert_file_exists "why.txt" \
  "why.txt — explain non-terminating error behavior in why.txt"

assert_file_contains "why.txt" '[Nn]on.?terminat|[Ee]rror.?[Aa]ction|[Ss]top' \
  "why.txt — must mention non-terminating, ErrorAction, or Stop"

ck_summary
