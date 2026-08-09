#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L3.6}"
: "${LAB_CHECKLIB:?run this via: lab check soc L3.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=y"
assert_file_contains_fixed ".answers.norm" "q2=y"
assert_file_contains_fixed ".answers.norm" "q3=y"
assert_file_contains_fixed ".answers.norm" "q4=n"
CERT_BIN="cert"util
assert_file_contains_fixed ".answers.norm" "q5=${CERT_BIN}.exe"
assert_file_contains_fixed ".answers.norm" "q6=t1059.001"

ck_summary
