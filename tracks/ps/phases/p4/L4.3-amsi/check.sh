#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "notes.txt" \
  "notes.txt — record what AMSI scans, its classification, and the bypass ATT&CK ID"

assert_file_contains "notes.txt" '[Dd]e-?obfuscat|[Rr]untime|[Dd]e-?cod' \
  "notes.txt — must mention de-obfuscated content, runtime, or decoded (what AMSI actually scans)"

assert_file_contains "notes.txt" '[Rr]eal [Cc]ontrol|[Tt]elemetry|[Dd]etectable' \
  "notes.txt — must mention real control, telemetry, or detectable (AMSI's L0.3 classification)"

assert_file_contains "notes.txt" '[Tt]1562' \
  "notes.txt — must cite ATT&CK T1562 (Impair Defenses)"

ck_summary
