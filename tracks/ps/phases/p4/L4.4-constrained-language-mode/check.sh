#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "notes.txt" \
  "notes.txt — record what CLM blocks and its enforcement dependency"

assert_file_contains "notes.txt" '\.[Nn][Ee][Tt]|[Aa][Dd][Dd]-[Tt][Yy][Pp][Ee]|\b[Cc][Oo][Mm]\b|[Cc]om[Oo]bject' \
  "notes.txt — must mention .NET type access, Add-Type, or COM (what CLM blocks)"

assert_file_contains "notes.txt" '[Ww][Dd][Aa][Cc]|[Aa][Pp][Pp][Ll][Oo][Cc][Kk][Ee][Rr]' \
  "notes.txt — must mention WDAC or AppLocker (the enforcement engines)"

assert_file_contains "notes.txt" '[Ee][Nn][Ff][Oo][Rr][Cc]' \
  "notes.txt — must mention enforcement (CLM is only a boundary when enforced)"

ck_summary
