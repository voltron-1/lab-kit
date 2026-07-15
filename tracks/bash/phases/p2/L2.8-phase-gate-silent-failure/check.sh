#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.8}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "broken-run.txt" 'archived: ERROR lines' \
  "step 2 — capture the ORIGINAL broken run before fixing (the lie is evidence)"
assert_file_contains "broken-run.txt" '^exit=0$' \
  "broken-run.txt needs the appended exit= line — the lie includes the code"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — which command's TARGET does not exist? read each line's operands again"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — one token on the cp line throws a command's stderr away entirely; which one, and where does it send it?"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — nothing stopped the script, and the commands after the failure all succeeded"
assert_file_contains "answers.txt" '^q4=a$' \
  "q4 — which lab of this phase exists to stop scripts at their first failure?"
assert_cmd_ok "fixed script succeeds on the shipped log" \
  "step 5 — your fixed script must archive app.log and exit 0" \
  -- bash -- archive-errors.sh app.log
assert_file_exists "archive/errors.txt" \
  "the archive the team reads is archive/ — the typo'd directory name is part of the bug"
assert_output_contains "all three ERROR lines archived" '^3$' \
  "archive/errors.txt must hold exactly the 3 ERROR lines from app.log" \
  -- grep -c ERROR archive/errors.txt
assert_cmd_fails "honesty test: a missing log must be FATAL, not narrated over" \
  "run: bash archive-errors.sh missing.log — a dead grep must stop the script (L2.2 preamble or || exit guards)" \
  -- bash -- archive-errors.sh missing.log
ck_summary
