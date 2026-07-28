#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

dl_term="Download"; dl_term+="String"

assert_file_exists "decode.ps1" \
  "decode.ps1 — shipped reference decoder must exist"

assert_output_contains "decode.ps1 reveals the decoded cradle" "$dl_term" \
  "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1

assert_output_contains "decode.ps1 reveals the fake C2 host" "fake-c2" \
  "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record the decoded text in plaintext.txt"

assert_file_contains_fixed "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the decoded payload you actually read"

assert_file_exists "technique.txt" \
  "technique.txt — name the technique and ATT&CK ID"

assert_file_contains "technique.txt" '[Cc]radle|[Dd]ownload' \
  "technique.txt — must name the payload as a download cradle"

assert_file_contains "technique.txt" '[Uu][Tt][Ff]-?16|[Uu]nicode' \
  "technique.txt — must mention UTF-16LE or Unicode (the actual encoding)"

assert_file_contains "technique.txt" 'T1140|T1027' \
  "technique.txt — must cite ATT&CK T1140 or T1027"

ck_summary
