#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.5}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=203.0.113[.]66"
assert_file_contains_fixed ".answers.norm" "q2=25"
assert_file_contains_fixed ".answers.norm" "q3=root"
assert_file_contains_fixed ".answers.norm" "q4=websvc"
assert_file_contains_fixed ".answers.norm" "q5=0"
assert_file_contains_fixed ".answers.norm" "q6=hxxp://cdn.stonewick[.]example/u.sh"

ck_summary
