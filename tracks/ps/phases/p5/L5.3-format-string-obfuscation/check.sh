#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

kw_lower="i"; kw_lower+="ex"
kw_mixed="I"; kw_mixed+="Ex"

assert_file_exists "fmt.ps1" \
  "fmt.ps1 — shipped reference probe must exist"

assert_output_contains "fmt.ps1 resolves the 3-arg reordered format" "reordered 3-arg format: ${kw_mixed}" \
  "run: pwsh -File fmt.ps1" -- pwsh -NoProfile -NonInteractive -File fmt.ps1

assert_output_contains "fmt.ps1 resolves the 2-arg reordered format" "reordered 2-arg format: ${kw_lower}" \
  "run: pwsh -File fmt.ps1" -- pwsh -NoProfile -NonInteractive -File fmt.ps1

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each format expression resolves to"

assert_file_contains "plaintext.txt" "${kw_lower}|${kw_mixed}" \
  "plaintext.txt — must show the keyword each format expression resolves to"

ck_summary
