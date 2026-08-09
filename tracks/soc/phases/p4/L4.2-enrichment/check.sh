#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_exists "vt_mal.txt"
assert_file_exists "pdns_domains.txt"

assert_file_contains_fixed "vt_mal.txt" "31"
assert_file_contains_fixed "pdns_domains.txt" "c2.stonewick.example"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=31"
assert_file_contains_fixed ".answers.norm" "q2=c2.stonewick[.]example"
assert_file_contains_fixed ".answers.norm" "q3=2026-02-27"
assert_file_contains_fixed ".answers.norm" "q4=52"
assert_file_contains_fixed ".answers.norm" "q5=passive-dns"

ck_summary
