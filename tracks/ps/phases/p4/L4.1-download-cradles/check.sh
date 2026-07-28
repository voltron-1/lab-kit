#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "cradle-variants.txt" \
  "cradle-variants.txt — shipped reference file must exist"

assert_file_exists "audit.md" \
  "audit.md — record the three-transport cradle audit in audit.md"

assert_file_contains_fixed "audit.md" "DownloadString" \
  "audit.md — must mention DownloadString (variants 1-2)"

assert_file_contains "audit.md" '[Bb][Ii][Tt][Ss]' \
  "audit.md — must mention Start-BitsTransfer or BITS (variant 3)"

assert_file_contains "audit.md" '[Ff]ileless|[Mm]emory' \
  "audit.md — must mention Fileless or Memory (variants 1-2 leave no disk artifact)"

assert_file_contains "audit.md" '[Bb][Ii][Tt][Ss].{0,40}([Dd]isk|[Dd]rop)|([Dd]isk|[Dd]rop).{0,40}[Bb][Ii][Tt][Ss]' \
  "audit.md — must explicitly contrast BITS against the fileless variants (mention BITS and disk/drop together, not as separate unrelated facts)"

assert_file_contains "audit.md" 'T1105|T1059|T1197' \
  "audit.md — must cite an ATT&CK ID (T1105, T1059.001, and/or T1197 for BITS Jobs)"

ck_summary
