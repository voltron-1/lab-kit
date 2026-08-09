#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L6.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L6.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=2026-03-12t20:15:33z"
assert_file_contains_fixed ".answers.norm" "q_order=e4,e1,e2,e3,e5,e6,e7"
assert_file_contains_fixed ".answers.norm" "q2=cm-0311-0142"
assert_file_contains_fixed ".answers.norm" "q3=event.ingested"
assert_file_contains_fixed ".answers.norm" "q4=-05:00"

ck_summary
