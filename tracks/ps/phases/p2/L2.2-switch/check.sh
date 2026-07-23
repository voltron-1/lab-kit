#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "fallthrough.ps1" \
  "fallthrough.ps1 — reference probe script must exist"

assert_output_contains "fallthrough outputs DIGITS" "DIGITS" \
  "run: pwsh -File fallthrough.ps1" \
  -- pwsh -NoProfile -NonInteractive -File fallthrough.ps1

assert_output_contains "fallthrough outputs HAS41" "HAS41" \
  "run: pwsh -File fallthrough.ps1" \
  -- pwsh -NoProfile -NonInteractive -File fallthrough.ps1

assert_file_exists "events.log" \
  "events.log — reference log file must exist"

assert_file_exists "scanlog.ps1" \
  "scanlog.ps1 — reference probe script must exist"

assert_output_contains "switch -File reads lines and matches FAILED" "HIT:" \
  "run: pwsh -File scanlog.ps1" \
  -- pwsh -NoProfile -NonInteractive -File scanlog.ps1

assert_file_exists "notes.txt" \
  "notes.txt — explain fall-through behavior in notes.txt"

assert_file_contains "notes.txt" '[Bb]reak|[Ff]all' \
  "notes.txt — must mention break or fall"

ck_summary
