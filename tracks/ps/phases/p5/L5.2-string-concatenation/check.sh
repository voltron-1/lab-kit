#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

kw_term="i"; kw_term+="ex"

assert_file_exists "concat.ps1" \
  "concat.ps1 — shipped reference probe must exist"

assert_file_contains_fixed "concat.ps1" '[char]105 + [char]101 + [char]120' \
  "concat.ps1 — the shipped char-code reconstruction must be present and unmodified"

assert_output_contains "concat.ps1 reassembles the keyword via +" "$kw_term" \
  "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1

assert_output_contains "concat.ps1 reassembles the second keyword via -join" "Download" \
  "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1

assert_output_contains "concat.ps1 reassembles the keyword via char codes" "char codes:.*${kw_term}" \
  "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each fragmented piece reassembles to"

assert_file_contains "plaintext.txt" "$kw_term" \
  "plaintext.txt — must show the reassembled first keyword"

assert_file_contains "plaintext.txt" "Download" \
  "plaintext.txt — must show the reassembled second keyword"

ck_summary
