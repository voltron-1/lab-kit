#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "members.txt" \
  "members.txt — export Get-Process pwsh | Get-Member into members.txt"

assert_file_contains_fixed "members.txt" "System.Diagnostics.Process" \
  "members.txt — must contain TypeName: System.Diagnostics.Process"

assert_file_contains "members.txt" 'Method' \
  "members.txt — must contain MemberType Method"

assert_file_contains "members.txt" 'Property' \
  "members.txt — must contain MemberType Property"

assert_file_exists "decode.txt" \
  "decode.txt — export (Get-Date) | Get-Member into decode.txt"

assert_file_contains_fixed "decode.txt" "System.DateTime" \
  "decode.txt — must contain TypeName: System.DateTime"

ck_summary
