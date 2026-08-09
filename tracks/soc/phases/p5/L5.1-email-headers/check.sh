#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "reported.eml"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=198.51.100[.]71"
assert_file_contains_fixed ".answers.norm" "q2=fail"
assert_file_contains_fixed ".answers.norm" "q3=fail"
assert_file_contains_fixed ".answers.norm" "q4=fail"
assert_file_contains_fixed ".answers.norm" "q5=copperm1ne-billing[.]example"
assert_file_contains_fixed ".answers.norm" "q6=n"

ck_summary
