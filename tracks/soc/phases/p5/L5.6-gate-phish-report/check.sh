#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.6}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "report.md"

if [[ -f "report.md" ]]; then
  tr '[:upper:]' '[:lower:]' < report.md | tr -d '\r' | sed 's@[[:space:]]*$@@' > .report.norm
else
  : > .report.norm
fi

# 1. Structure assertions
assert_file_contains ".report.norm" "^## *timeline"
assert_file_contains ".report.norm" "t1566\.001"
assert_file_contains ".report.norm" "^## *verdict"
assert_file_contains ".report.norm" "(phish|malicious|true positive)"
assert_file_contains ".report.norm" "^## *recommendation"
assert_file_contains ".report.norm" "\[\.\]"

# 2. Defang GATE — report must NOT contain raw IOC forms
assert_file_not_contains "report.md" "http://" # lint-allow: URI scheme matched in defang gate
assert_file_not_contains "report.md" "cdn.stonewick.example"
assert_file_not_contains "report.md" "203.0.113.66"
assert_file_not_contains "report.md" "198.51.100.71"

ck_summary
