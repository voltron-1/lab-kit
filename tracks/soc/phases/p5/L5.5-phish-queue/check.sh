#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.5}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=phish"
assert_file_contains_fixed ".answers.norm" "q2=phish"
assert_file_contains_fixed ".answers.norm" "q3=legit"
assert_file_contains_fixed ".answers.norm" "q4=spam"
assert_file_contains_fixed ".answers.norm" "q5=legit"
assert_file_contains_fixed ".answers.norm" "q6=phish"

ck_summary
