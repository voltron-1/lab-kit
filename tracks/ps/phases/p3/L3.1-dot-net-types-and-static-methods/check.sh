#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "b64.ps1" \
  "b64.ps1 — reference probe script must exist"

assert_output_contains "base64 of hi is aGk=" "aGk=" \
  "run: pwsh -File b64.ps1" \
  -- pwsh -NoProfile -NonInteractive -File b64.ps1

assert_file_exists "decode.ps1" \
  "decode.ps1 — reference probe script must exist"

assert_output_contains "UTF-16LE base64 round-trips to hi" "hi" \
  "run: pwsh -File decode.ps1" \
  -- pwsh -NoProfile -NonInteractive -File decode.ps1

assert_file_exists "notes.txt" \
  "notes.txt — record .NET analysis in notes.txt"

assert_file_contains_fixed "notes.txt" "System.Convert" \
  "notes.txt — must mention System.Convert"

assert_file_contains_fixed "notes.txt" "System.Net.WebClient" \
  "notes.txt — must mention System.Net.WebClient"

assert_file_contains "notes.txt" '[Bb]ase64' \
  "notes.txt — must mention Base64"

assert_file_contains "notes.txt" '[Dd]ownload|[Nn]etwork|[Ff]etch' \
  "notes.txt — must mention Download, Network, or Fetch"

ck_summary
