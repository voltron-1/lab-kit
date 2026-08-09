#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "auth-events.jsonl"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=spray"
assert_file_contains_fixed ".answers.norm" "q2=brute"
assert_file_contains_fixed ".answers.norm" "q3=svc_web"
assert_file_contains_fixed ".answers.norm" "q4=40"
assert_file_contains_fixed ".answers.norm" "q5=tp"
assert_file_contains_fixed ".answers.norm" "q6=203.0.113[.]66"

ck_summary
