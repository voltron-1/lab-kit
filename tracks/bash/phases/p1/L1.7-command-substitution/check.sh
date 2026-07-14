#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.7}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" "write p1..p5 into predictions.txt before running anything — one key=value per line"
assert_file_contains_fixed "predictions.txt" "p1=1|<2.4.1>" "p1 — rerun sample line p1 and transcribe its whole output line, | and <> included"
assert_file_contains_fixed "predictions.txt" "p2=2|<web01><web02>" "p2 — rerun sample line p2 and count the argv words the unquoted result produced"
assert_file_contains_fixed "predictions.txt" "p3=1|<web01 web02>" "p3 — rerun sample line p3; the double quotes change the word count vs p2"
assert_file_contains_fixed "predictions.txt" "p4=1|<L1.7>" "p4 — rerun sample line p4 from the workspace root and read it inside-out"
assert_file_contains "predictions.txt" '^p5=b$' "p5 — rerun the three-line transcript and watch which stream the error text used"
assert_output_contains "substitution feeds argv" '2\|<web01><web02>' "step p2 — the unquoted result splits into two argv words" -- bash -- argv.sh web01 web02
ck_summary
