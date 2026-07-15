#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt" \
  "step 4 — write keys q1..q6 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=0$' \
  "q1 — rerun experiment 1 and transcribe the digit; the empty expansion vanished before [ ran"
assert_file_contains "answers.txt" '^q2=1$' \
  "q2 — rerun experiment 2: [[ keeps its operand slot even when the expansion is empty"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — one letter: how many arguments did [ actually receive in experiment 1?"
assert_file_contains "answers.txt" '^q4=2$' \
  "q4 — rerun experiment 3: the split hands [ too many operands; transcribe the exit code"
assert_file_contains "answers.txt" '^q5=1$' \
  "q5 — inside [[ ]], > compares STRINGS; which sorts first, 10 or 9?"
assert_file_contains "answers.txt" '^q6=0$' \
  "q6 — (( )) is arithmetic: the comparison is true, and true flips to exit 0"
assert_output_contains "gatekeeper admits admin at low load" 'admit: admin' \
  "run: bash gatekeeper.sh admin 3" -- bash -- gatekeeper.sh admin 3
assert_cmd_fails "gatekeeper denies non-admin" \
  "run: bash gatekeeper.sh guest 3 — read the deny branch" -- bash -- gatekeeper.sh guest 3
ck_summary
