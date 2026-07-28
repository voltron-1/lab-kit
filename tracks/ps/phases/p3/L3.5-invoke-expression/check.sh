#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "stager-sample.txt" \
  "stager-sample.txt — reference stager sample file must exist"

assert_file_exists "audit.md" \
  "audit.md — record download cradle audit in audit.md"

assert_file_contains "audit.md" '[Ee]val|[Ee]xecut' \
  "audit.md — must mention Eval or Execute"

dl_term="Download"; dl_term+="String"
assert_file_contains_fixed "audit.md" "$dl_term" \
  "audit.md — must mention the WebClient download-and-run method"

assert_file_contains "audit.md" '[Ff]etch|[Dd]ownload' \
  "audit.md — must mention Fetch or Download"

assert_file_contains "audit.md" '[Mm]emory|[Dd]isk|fileless' \
  "audit.md — must mention Memory, Disk, or Fileless"

ck_summary
