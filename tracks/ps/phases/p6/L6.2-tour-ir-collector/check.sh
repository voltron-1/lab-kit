#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L6.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L6.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# Nothing here runs the collector. Several of its cmdlets are Windows-only, and the
# whole point of a TOUR is reading rather than executing -- so the shipped excerpt
# and the shipped report are static, and grading is entirely on the learner's readout.

assert_file_exists "collector.ps1" \
  "collector.ps1 — shipped collector excerpt must exist"

assert_file_exists "sample-report.json" \
  "sample-report.json — shipped sample output must exist"

assert_file_exists "readout.md" \
  "readout.md — name the evidence categories this collector gathers"

assert_file_contains_i "readout.md" "process" \
  "readout.md — must name the running-process evidence"

assert_file_contains_i "readout.md" "autostart|startup|persist|run key" \
  "readout.md — must name the autostart evidence (where persistence lives)"

assert_file_contains_i "readout.md" "logon|4624" \
  "readout.md — must name the logon-event evidence"

assert_file_contains_i "readout.md" "structur|serial|parse|diff|ingest" \
  "readout.md — must say why the collector serializes to a structured report"

ck_summary
