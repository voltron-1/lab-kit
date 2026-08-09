#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "security.json"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q6='

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=4624"
assert_file_contains_fixed ".answers.norm" "q2=4625"
assert_file_contains_fixed ".answers.norm" "q3=3"
assert_file_contains_fixed ".answers.norm" "q4=4720"
assert_file_contains_fixed ".answers.norm" "q5=4688"
assert_file_contains_fixed ".answers.norm" "q6=cm-0311-0142"

ck_summary
