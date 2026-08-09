#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.7}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "queue.json"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=tp"
assert_file_contains_fixed ".answers.norm" "q1e=cm-0311-0142"
assert_file_contains_fixed ".answers.norm" "q2=btp"
assert_file_contains_fixed ".answers.norm" "q3=tp"
assert_file_contains_fixed ".answers.norm" "q3e=cm-0312-0310"
assert_file_contains_fixed ".answers.norm" "q4=fp"
assert_file_contains_fixed ".answers.norm" "q5=tp"
assert_file_contains_fixed ".answers.norm" "q5e=cm-0311-0201"
assert_file_contains_fixed ".answers.norm" "q6=btp"
assert_file_contains_fixed ".answers.norm" "q7=fp"
assert_file_contains_fixed ".answers.norm" "q8=fp"
assert_file_contains_fixed ".answers.norm" "q9=btp"
assert_file_contains_fixed ".answers.norm" "q10=tp"
assert_file_contains_fixed ".answers.norm" "q10e=cm-0311-0181"
assert_file_contains_fixed ".answers.norm" "q11=fp"
assert_file_contains_fixed ".answers.norm" "q12=tp"

ck_summary
