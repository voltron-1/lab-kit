#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "sysmon.json"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=pg-ps1"
assert_file_contains_fixed ".answers.norm" "q2=winword.exe"
assert_file_contains_fixed ".answers.norm" "q3=cmd.exe"
assert_file_contains_fixed ".answers.norm" "q4=whoami /all"  # lint-allow: command line argument check
assert_file_contains_fixed ".answers.norm" "q5=3"
assert_file_contains_fixed ".answers.norm" "q6=cm-0311-0201"

ck_summary
