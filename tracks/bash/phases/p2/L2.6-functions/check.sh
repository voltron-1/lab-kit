#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt" \
  "step 4 — write keys q1..q5 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=7$' \
  "q1 — rerun experiment 1 and transcribe the digit"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — one letter: which channel does return use, and which does capture read?"
assert_file_contains "answers.txt" '^q3=changed$' \
  "q3 — rerun experiment 3: without local, whose variable did the function edit?"
assert_file_contains "answers.txt" '^q4=44$' \
  "q4 — the verdict channel is one byte wide: 300 wraps. rerun experiment 4"
assert_file_contains "answers.txt" '^q5=b$' \
  "q5 — reread the n= line in healthcheck.sh: what is being captured there?"
assert_output_contains "healthcheck names the state" 'status: degraded' \
  "run: bash healthcheck.sh — app.log carries two ERROR lines" -- bash -- healthcheck.sh
ck_summary
