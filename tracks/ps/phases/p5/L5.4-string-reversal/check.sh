#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

kw_term="i"; kw_term+="ex"
dl_term="Download"; dl_term+="String"

assert_file_exists "rev.ps1" \
  "rev.ps1 — shipped reference probe must exist"

assert_file_contains_fixed "rev.ps1" "gnirtSdaolnwoD" \
  "rev.ps1 — the shipped reversed literal must be present and unmodified"

assert_output_contains "rev.ps1 reverses the first keyword" "reversed keyword 1: ${kw_term}" \
  "run: pwsh -File rev.ps1" -- pwsh -NoProfile -NonInteractive -File rev.ps1

assert_output_contains "rev.ps1 reverses the second keyword" "reversed keyword 2: ${dl_term}" \
  "run: pwsh -File rev.ps1" -- pwsh -NoProfile -NonInteractive -File rev.ps1

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each reversed literal un-reverses to"

assert_file_contains "plaintext.txt" "$kw_term" \
  "plaintext.txt — must show the first un-reversed keyword"

assert_file_contains_fixed "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the second un-reversed keyword"

ck_summary
