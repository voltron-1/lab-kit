#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=grounded"
assert_file_contains_fixed ".answers.norm" "q2=flawed"
assert_file_contains_fixed ".answers.norm" "q2f=hallucinated"
assert_file_contains_fixed ".answers.norm" "q3=grounded"
assert_file_contains_fixed ".answers.norm" "q4=flawed"
assert_file_contains_fixed ".answers.norm" "q4f=wrongpivot"
assert_file_contains_fixed ".answers.norm" "q5=flawed"
assert_file_contains_fixed ".answers.norm" "q5f=ungrounded"
assert_file_contains_fixed ".answers.norm" "q_hall=cm-9999-9999"

ck_summary
