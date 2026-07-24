#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "tool.ps1" \
  "tool.ps1 — reference function script must exist"

assert_file_exists "probe.ps1" \
  "probe.ps1 — reference probe script must exist"

assert_output_contains "advanced function exposes common parameter Verbose" "True" \
  "run: pwsh -File probe.ps1" \
  -- pwsh -NoProfile -NonInteractive -File probe.ps1

assert_file_exists "answers.txt" \
  "answers.txt — record function analysis in answers.txt"

assert_file_contains_fixed "answers.txt" "Name" \
  "answers.txt — must name parameter Name"

assert_file_contains "answers.txt" '[Mm]andator' \
  "answers.txt — must mention Mandatory"

assert_file_contains "answers.txt" '[Vv]erbose|[Cc]ommon' \
  "answers.txt — must mention Verbose or Common"

ck_summary
