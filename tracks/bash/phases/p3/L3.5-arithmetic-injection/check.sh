#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' \
  "which line evaluates untrusted input as an arithmetic expression?"
assert_file_contains "answers.txt" '^flaw=arith-cmdsub$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — validate the input before it reaches (( ))"
assert_file_contains "answers.txt" '(numeric|digit)' \
  "the fix must reject non-numeric input before (( ))"

# --- hardened script must exist before we try to run it ---
assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — reject anything that isn't all digits before (( ))"

# --- hardened behavior: reject an injection payload, still accept a real number.
# No decoy/fence needed — this lab never runs the flawed calc.sh, and the only
# payload check.sh itself uses is inert once the guard fires. ---
injection_payload="a[\$(id -u)]"
assert_cmd_fails "hardened calc rejects a[\$(id -u)] injection" \
  "your numeric guard must refuse anything that isn't all digits" \
  -- bash -- hardened.sh "$injection_payload"
assert_output_contains "hardened calc still doubles a real number" '^result=10$' \
  "a valid numeric input must still work: 5 -> result=10" \
  -- bash -- hardened.sh 5
ck_summary
