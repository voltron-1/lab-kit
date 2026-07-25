#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "remoting-params.ps1" \
  "remoting-params.ps1 — reference probe script must exist"

assert_output_contains "Invoke-Command exposes -ComputerName" "HAS-COMPUTERNAME" \
  "run: pwsh -File remoting-params.ps1" \
  -- pwsh -NoProfile -NonInteractive -File remoting-params.ps1

assert_file_exists "lateral.txt" \
  "lateral.txt — record remoting analysis in lateral.txt"

assert_file_contains_fixed "lateral.txt" "Invoke-Command" \
  "lateral.txt — must mention Invoke-Command"

assert_file_contains "lateral.txt" '[Rr]emote|[Ll]ateral' \
  "lateral.txt — must mention Remote or Lateral"

assert_file_contains "lateral.txt" 'T1021|WinRM' \
  "lateral.txt — must mention T1021 or WinRM"

ck_summary
