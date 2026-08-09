#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=malicious"
assert_file_contains_fixed ".answers.norm" "q2=c2.stonewick[.]example"
assert_file_contains_fixed ".answers.norm" "q3=t1566.001"
assert_file_contains_fixed ".answers.norm" "q4=onedriveupd"
assert_file_contains_fixed ".answers.norm" "q5=y"

ck_summary
