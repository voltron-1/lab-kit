#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L6.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L6.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=wks-acct-07"
assert_file_contains_fixed ".answers.norm" "q2=cm-0311-0201"
assert_file_contains_fixed ".answers.norm" "q3=c2.stonewick[.]example"
assert_file_contains_fixed ".answers.norm" "q4=onedriveupd"
assert_file_contains_fixed ".answers.norm" "q5=fs01"
assert_file_contains_fixed ".answers.norm" "q6=cm-0311-0244"

ck_summary
