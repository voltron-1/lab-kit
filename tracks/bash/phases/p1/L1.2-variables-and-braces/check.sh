#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists 'predictions.txt' 'step 3 — write keys p1..p4 into predictions.txt before running anything'
assert_file_contains_fixed 'predictions.txt' 'p1=1|<world>' "p1 — rerun step 5 (v=world, then: bash argv.sh \$v) and transcribe the exact output line"
assert_file_contains_fixed 'predictions.txt' 'p2=1|<worldwide>' "p2 — rerun step 6 (bash argv.sh \${v}wide) and transcribe the exact output line"
assert_file_contains_fixed 'predictions.txt' 'p3=0|' "p3 — rerun step 7 (bash argv.sh \$vwide) and transcribe the exact output line"
assert_file_contains 'predictions.txt' '^p4=b$' 'p4 — one lowercase letter; rerun step 8 (v = world, with spaces) and watch what the shell tries to do'

ck_summary
