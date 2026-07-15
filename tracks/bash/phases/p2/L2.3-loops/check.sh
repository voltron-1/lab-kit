#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" \
  "step 3 — write keys p1..p6 into predictions.txt before running anything"
assert_file_contains "predictions.txt" '^p1=3$' \
  "p1 — count the lines the word-list loop prints; rerun sample p1"
assert_file_contains "predictions.txt" '^p2=loading web01.conf$' \
  "p2 — the FIRST line the glob loop prints; sorted glob order decides which .conf comes first"
assert_file_contains "predictions.txt" '^p3=7$' \
  "p3 — unquoted command substitution word-splits before for ever runs; count the WORDS in tasks.txt"
assert_file_contains "predictions.txt" '^p4=2$' \
  "p4 — plain read drops a final line that has no newline; rerun sample p4 and count"
assert_file_contains "predictions.txt" '^p5=3$' \
  "p5 — readlines.sh carries the guard that rescues the last line; rerun sample p5"
assert_file_contains_fixed "predictions.txt" 'p6=got *.missing' \
  "p6 — a glob that matches nothing stays literal, and the loop still runs once on it"
assert_output_contains "the guard rescues the unterminated last line" 'rotate keys' \
  "run: bash readlines.sh tasks.txt" -- bash -- readlines.sh tasks.txt
ck_summary
