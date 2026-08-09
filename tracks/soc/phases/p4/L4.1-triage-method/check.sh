#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "alert.json"
assert_file_exists "events.jsonl"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=cm-r-0159"
assert_file_contains_fixed ".answers.norm" "q2=cm-0311-0201"
assert_file_contains_fixed ".answers.norm" "q3=n"
assert_file_contains_fixed ".answers.norm" "q4=1"
assert_file_contains_fixed ".answers.norm" "q5=tp"

ck_summary
