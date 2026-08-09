#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=runkey"
assert_file_contains_fixed ".answers.norm" "q2=scheduledtask"
assert_file_contains_fixed ".answers.norm" "q3=service"
assert_file_contains_fixed ".answers.norm" "q4=cron"
assert_file_contains_fixed ".answers.norm" "q5=hxxp://cdn.stonewick[.]example/u.sh"
assert_file_contains_fixed ".answers.norm" "q6=cm-0311-0181"

ck_summary
