#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.7}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "report.md"

if [[ -f "report.md" ]]; then
  tr '[:upper:]' '[:lower:]' < report.md | tr -d '\r' | sed 's@[[:space:]]*$@@' > .report.norm
else
  : > .report.norm
fi

# 1. Structure assertions
assert_file_contains ".report.norm" "^## *scope"
assert_file_contains ".report.norm" "^## *timeline"
assert_file_contains ".report.norm" "cm-[0-9]{4}-[0-9]{4}"
assert_file_contains ".report.norm" "t1059\.001"
assert_file_contains ".report.norm" "^## *verdict"
assert_file_contains ".report.norm" "(phish|malicious|true positive)"
assert_file_contains ".report.norm" "^## *recommendation"
assert_file_contains ".report.norm" "^## *tuning recommendation"
assert_file_contains ".report.norm" "(cmdline:winword->powershell|host:srv-backup|path:securityawareness)"
assert_file_contains ".report.norm" "\[\.\]"

# 2. Defang GATE — report must NOT contain raw IOC forms
assert_file_not_contains "report.md" "http://" # lint-allow: URI scheme matched in defang gate
assert_file_not_contains "report.md" "c2.stonewick.example"
assert_file_not_contains "report.md" "203.0.113.66"
assert_file_not_contains "report.md" "198.51.100.71"

ck_summary
