#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt" "step 8 — write answers.txt in the workspace root: keys q1..q4, one key=value per line"
assert_file_contains "answers.txt" '^q1=1$' "q1 wants a digit — step 3: bash pulse.sh, then echo \$? with nothing in between"
assert_file_contains "answers.txt" '^q2=1$' "q2 wants a digit — step 5: grep -q FATAL app.log; echo \$? — silence still has a verdict"
assert_file_contains "answers.txt" '^q3=b$' "q3 — step 7: which command ran LAST before the second echo, and did it succeed?"
assert_file_contains "answers.txt" '^q4=b$' "q4 — grep -q prints nothing at all; reread pulse.sh line 4"
assert_cmd_fails "pulse.sh exits nonzero on a degraded log" "run: bash pulse.sh — the shipped log has an ERROR line" -- bash -- pulse.sh
assert_output_contains "pulse.sh names the state" 'status: degraded' "read the if-branch in pulse.sh" -- bash -- pulse.sh
ck_summary
