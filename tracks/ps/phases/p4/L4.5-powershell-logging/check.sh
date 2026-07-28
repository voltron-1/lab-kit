#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "read4104.ps1" \
  "read4104.ps1 — shipped reference reader must exist"

dl_term="Download"; dl_term+="String"

assert_output_contains "read4104.ps1 prints the recorded ScriptBlockText" "$dl_term" \
  "run: pwsh -File read4104.ps1" -- pwsh -NoProfile -NonInteractive -File read4104.ps1

assert_file_exists "readout.md" \
  "readout.md — record the Event ID, what ScriptBlockText shows, and the log source in readout.md"

assert_file_contains "readout.md" '4104' \
  "readout.md — must cite Event ID 4104"

assert_file_contains_fixed "readout.md" "$dl_term" \
  "readout.md — must show the WebClient download-and-run payload you actually read from ScriptBlockText"

assert_file_contains "readout.md" '[Ss]cript.?[Bb]lock' \
  "readout.md — must name ScriptBlock (logging) as the source that records de-obfuscated content"

ck_summary
