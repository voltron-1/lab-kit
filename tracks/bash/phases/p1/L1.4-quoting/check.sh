#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" \
  "step 3 — write all five predictions before running anything (keys p1..p5)"
assert_file_contains_fixed "predictions.txt" "p1=1|<\$user>" \
  "p1 — single quotes: rerun sample line 1 and transcribe the whole output line"
assert_file_contains_fixed "predictions.txt" "p2=1|<root>" \
  "p2 — double quotes: rerun sample line 2 and transcribe the whole output line"
assert_file_contains_fixed "predictions.txt" "p3=1|<phase root>" \
  "p3 — expansion inside one quoted word: rerun sample line 3 and transcribe"
assert_file_contains_fixed "predictions.txt" "p4=2|<phase><root>" \
  "p4 — two separate words: rerun sample line 4 and transcribe"
assert_file_contains_fixed "predictions.txt" "p5=1|<'root'>" \
  "p5 — single quotes inside doubles are plain characters: rerun line 5 and transcribe"
assert_output_contains 'double quotes keep one word' '1\|<phase root>' \
  'run: bash argv.sh "phase root"' -- bash -- argv.sh 'phase root'

ck_summary
