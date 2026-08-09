#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L6.5}"
: "${LAB_CHECKLIB:?run this via: lab check soc L6.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1a=tier2"
assert_file_contains_fixed ".answers.norm" "q1t=immediate"
assert_file_contains_fixed ".answers.norm" "q2a=handoff"
assert_file_contains_fixed ".answers.norm" "q2t=eos"
assert_file_contains_fixed ".answers.norm" "q3a=user"
assert_file_contains_fixed ".answers.norm" "q3t=routine"
assert_file_contains_fixed ".answers.norm" "q4a=handoff"
assert_file_contains_fixed ".answers.norm" "q4t=eos"
assert_file_contains_fixed ".answers.norm" "q5=watch"

ck_summary
