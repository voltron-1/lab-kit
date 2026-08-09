#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.5}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "queue.json"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=p1"
assert_file_contains_fixed ".answers.norm" "q2=p1"
assert_file_contains_fixed ".answers.norm" "q3=p1"
assert_file_contains_fixed ".answers.norm" "q4=p3"
assert_file_contains_fixed ".answers.norm" "q5=p3"
assert_file_contains_fixed ".answers.norm" "q6=p2"
assert_file_contains_fixed ".answers.norm" "q7=p2"
assert_file_contains_fixed ".answers.norm" "q8=p3"
assert_file_contains_fixed ".answers.norm" "q9=p2"
assert_file_contains_fixed ".answers.norm" "q10=p3"

ck_summary
