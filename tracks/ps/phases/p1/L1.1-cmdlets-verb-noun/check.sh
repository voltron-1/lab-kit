#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "verbs.txt" \
  "verbs.txt — export approved verbs using Get-Verb into verbs.txt"

assert_file_contains "verbs.txt" 'Get' \
  "verbs.txt — must contain approved verb Get"

assert_file_contains "verbs.txt" 'Set' \
  "verbs.txt — must contain approved verb Set"

assert_file_contains "verbs.txt" 'Invoke' \
  "verbs.txt — must contain approved verb Invoke"

assert_file_contains "verbs.txt" 'Remove' \
  "verbs.txt — must contain approved verb Remove"

assert_file_contains "verbs.txt" 'Stop' \
  "verbs.txt — must contain approved verb Stop"

assert_file_contains "verbs.txt" 'New' \
  "verbs.txt — must contain approved verb New"

assert_file_contains "decode.txt" 'Invoke-Expression' \
  "decode.txt — must list Invoke-Expression"

assert_file_contains "decode.txt" '[Ee]xecut(e|es|ing|ion)' \
  "decode.txt — must map Invoke-Expression to the execute side-effect class"

ck_summary
