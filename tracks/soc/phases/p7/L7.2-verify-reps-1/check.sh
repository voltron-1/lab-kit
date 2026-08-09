#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.2}"
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
assert_file_contains_fixed ".answers.norm" "q2f=contradicted"
assert_file_contains_fixed ".answers.norm" "q2e=cm-0311-0181"
assert_file_contains_fixed ".answers.norm" "q3=grounded"

ck_summary
