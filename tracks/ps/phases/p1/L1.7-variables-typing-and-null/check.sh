#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "interp.ps1" \
  "interp.ps1 — reference probe script must exist"

assert_output_contains "empty interpolation renders as value:[]" "value:\[\]" \
  "run: pwsh -File interp.ps1" \
  -- pwsh -NoProfile -NonInteractive -File interp.ps1

assert_file_exists "ntype.ps1" \
  "ntype.ps1 — reference probe script must exist"

assert_output_contains "coerced type is Int32" "Int32" \
  "run: pwsh -File ntype.ps1" \
  -- pwsh -NoProfile -NonInteractive -File ntype.ps1

assert_file_exists "decode.txt" \
  "decode.txt — explain why unassigned variables render empty"

assert_file_contains "decode.txt" '[Nn]ull' \
  "decode.txt — must mention \$null"

ck_summary
