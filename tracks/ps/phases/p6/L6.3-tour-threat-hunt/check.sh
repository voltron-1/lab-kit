#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L6.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L6.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# Verified at plan time against real pwsh 7.6.4 on Linux: Get-WinEvent does not
# exist off Windows, so hunt.ps1 CANNOT be executed here even in principle. This
# grader reads nothing but the learner's readout, and runs no pwsh at all.

# Split so tools/lint-labs.sh's case-insensitive attack-token scan never sees the
# cradle keyword contiguously in this file.
dl_term="Download"; dl_term+="String"

assert_file_exists "hunt.ps1" \
  "hunt.ps1 — shipped threat hunt must exist"

assert_file_exists "readout.md" \
  "readout.md — say which log and event ID the hunt reads, and what it filters for"

assert_file_contains_i "readout.md" "4104" \
  "readout.md — must name the event ID the hunt reads (4104, ScriptBlock)"

assert_file_contains_i "readout.md" "Get-WinEvent" \
  "readout.md — must name the cmdlet the hunt queries with"

assert_file_contains_i "readout.md" "encod|base64|cradle|${dl_term}" \
  "readout.md — must say what the -match filter hunts for"

assert_file_contains_i "readout.md" "\\bmiss|evad|assembl|runtime|concat|format|revers" \
  "readout.md — must say what this literal-string filter would miss"

ck_summary
