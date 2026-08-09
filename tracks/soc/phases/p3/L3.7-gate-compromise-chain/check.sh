#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.7}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=m.reyes"
assert_file_contains_fixed ".answers.norm" "q2=cm-0311-0142"
assert_file_contains_fixed ".answers.norm" "q3=powershell.exe"
assert_file_contains_fixed ".answers.norm" "q4=runkey"
assert_file_contains_fixed ".answers.norm" "q5=supportadmin"
assert_file_contains_fixed ".answers.norm" "q6=root"
assert_file_contains_fixed ".answers.norm" "q7=203.0.113[.]66"
assert_file_contains_fixed ".answers.norm" "q8=cm-0311-0244"

ck_summary
