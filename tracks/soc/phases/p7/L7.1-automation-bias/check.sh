#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=commission"
assert_file_contains_fixed ".answers.norm" "q2=omission"
assert_file_contains_fixed ".answers.norm" "q3=complacency"
assert_file_contains_fixed ".answers.norm" "q4=deskilling"
assert_file_contains_fixed ".answers.norm" "q5=anchoring"

ck_summary
