#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists 'predictions.txt' "write all four predictions (p1, p2, p3, p5) before running anything — step 2"
assert_file_contains_fixed 'predictions.txt' 'p1=2|<report><final.txt>' "p1 — bash argv.sh \$f: the expansion result is split on whitespace before argv.sh ever runs"
assert_file_contains_fixed 'predictions.txt' 'p2=1|<report final.txt>' "p2 — bash argv.sh \"\$f\": double quotes stop the split"
assert_file_contains 'predictions.txt' '^p3=b$' "p3 — one letter: trace the exact words cp receives after \$f expands unquoted"
assert_file_contains 'predictions.txt' '^p5=b$' "p5 — one letter: rerun echo \$opt and look closely at what printed"
assert_file_exists 'backup/report final.txt' "step p4 — run the QUOTED copy: cp \"\$f\" backup/"
ck_summary
