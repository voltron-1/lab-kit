#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "hash.txt"

assert_file_contains_fixed "hash.txt" "55e9d81f361e14ec8998781f8ccdc3a0b160affa974681f31dd4a6d7537fc0f4"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=zip"
assert_file_contains_fixed ".answers.norm" "q2=y"
assert_file_contains_fixed ".answers.norm" "q3=receipt.pdf.exe"
assert_file_contains_fixed ".answers.norm" "q4=55e9d81f361e"
assert_file_contains_fixed ".answers.norm" "q5=hash"

ck_summary
