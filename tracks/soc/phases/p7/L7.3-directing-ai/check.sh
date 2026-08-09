#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=b"
assert_file_contains_fixed ".answers.norm" "q2=b"
assert_file_contains_fixed ".answers.norm" "q3=b"
assert_file_contains_fixed ".answers.norm" "q4=b"
assert_file_contains_fixed ".answers.norm" "q5=good"
assert_file_contains_fixed ".answers.norm" "q6=bad"
assert_file_contains_fixed ".answers.norm" "q7=good"
assert_file_contains_fixed ".answers.norm" "q8=bad"
assert_file_contains_fixed ".answers.norm" "q9=good"

ck_summary
