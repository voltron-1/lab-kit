#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L6.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L6.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  # Normalize and sort comma-separated list for q4
  raw_q4=$(grep '^q4=' answers.txt | cut -d= -f2- | tr '[:upper:]' '[:lower:]' | tr -d '\r' | tr ',' '\n' | sort | tr '\n' ',' | sed 's@,$@@')
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
  sed -i "s@^q4=.*@q4=${raw_q4}@" .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=1"
assert_file_contains_fixed ".answers.norm" "q2=wks-acct-07"
assert_file_contains_fixed ".answers.norm" "q3=4"
assert_file_contains_fixed ".answers.norm" "q4=fs01,web01,wks-acct-07,wks-eng-12"
assert_file_contains_fixed ".answers.norm" "q5=contained"

ck_summary
