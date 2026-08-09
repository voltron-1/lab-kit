#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=powershell.exe"
assert_file_contains_fixed ".answers.norm" "q2=pg-ps1"
assert_file_contains_fixed ".answers.norm" "q3=outlook.exe"
assert_file_contains_fixed ".answers.norm" "q4=3"
assert_file_contains_fixed ".answers.norm" "q5=execution"
assert_file_contains_fixed ".answers.norm" "q6=cm-0311-0201"

ck_summary
