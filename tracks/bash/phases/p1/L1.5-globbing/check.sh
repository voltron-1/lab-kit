#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists 'predictions.txt' 'step 2 — write the six p<N>= prediction lines before running anything'
assert_file_contains_fixed 'predictions.txt' 'p1=2|<app.log><error.log>' 'p1 — re-run: bash argv.sh *.log and transcribe the exact output line'
assert_file_contains_fixed 'predictions.txt' 'p2=2|<app.conf><app.log>' 'p2 — re-run: bash argv.sh app.* and transcribe the exact output line'
assert_file_contains_fixed 'predictions.txt' 'p3=1|<*.md>' 'p3 — readme.md sits inside sub/ and * never recurses; re-run: bash argv.sh *.md'
assert_file_contains_fixed 'predictions.txt' 'p4=4|<app.conf><app.log><argv.sh><error.log>' 'p4 — four entries start with a or e, and argv.sh sees itself; re-run: bash argv.sh [ae]*'
assert_file_contains_fixed 'predictions.txt' 'p5=2|<app.log><error.log>' 'p5 — pat expands first, then the unquoted result globs; re-run line p5 and transcribe'
assert_file_contains_fixed 'predictions.txt' 'p6=1|<*.log>' 'p6 — double quotes suppress the glob; re-run line p6 and transcribe'
ck_summary
