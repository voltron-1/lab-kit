#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt" \
  "step 3 — write keys q1..q4 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — rerun: bash triage.sh alert_web.log — which arm fired, and why that one?"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — case takes the FIRST match; what single change makes alert_* win the race?"
assert_file_contains "answers.txt" '^q3=2$' \
  "q3 — rerun the no-argument row and transcribe the digit from echo \$?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — no arm matched, no catch-all: what verdict does the case leave behind?"
assert_output_contains "first match wins" 'route: plain log scanner' \
  "run: bash triage.sh alert_web.log" -- bash -- triage.sh alert_web.log
assert_cmd_fails "no argument is a usage error" \
  "run: bash triage.sh with no argument — read the first arm" -- bash -- triage.sh
ck_summary
