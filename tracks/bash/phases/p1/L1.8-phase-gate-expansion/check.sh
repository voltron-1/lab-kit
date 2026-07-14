#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.8}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" 'step 2 — create predictions.txt with keys p1..p10 before running the script'
assert_file_contains "predictions.txt" '^p1=1:$' "p1 — line 5: is \$host_id one variable name, or \$host plus _id? (L1.2)"
assert_file_contains "predictions.txt" '^p2=2:web01_id$' "p2 — line 6: what does \${host} change about where the name ends? (L1.2)"
assert_file_contains_fixed "predictions.txt" 'p3=3:*.log' 'p3 — line 8: single quotes suppress every expansion, even a pattern that would match (L1.4)'
assert_file_contains "predictions.txt" '^p4=4:web01 web02$' 'p4 — line 9: double quotes expand but never split (L1.4)'
assert_file_contains "predictions.txt" '^p5=5:argc=2$' "p5 — lines 10-11: bare \$hosts splits on IFS whitespace; how many words? (L1.3)"
assert_file_contains "predictions.txt" '^p6=6:app.log error.log$' 'p6 — line 12: which files match *.log, in sorted order, and both %s get used (L1.5)'
assert_file_contains_fixed "predictions.txt" 'p7=7:*.conf' 'p7 — line 13: what happens to a glob that matches nothing? (L1.5)'
assert_file_contains "predictions.txt" '^p8=8:L1.8$' "p8 — line 14: inner \$(pwd) runs first; the lab runs from workspace/bash/L1.8 (L1.7)"
assert_file_contains "predictions.txt" '^p9=9:argc=2$' "p9 — lines 15-16: unquoted \$(cat hosts.txt) splits exactly like an unquoted variable (L1.7)"
assert_file_contains "predictions.txt" '^p10=10:rc=1$' "p10 — lines 17-18: app.log contains no FATAL, and \$? is the exit of the LAST command (L1.6)"
assert_output_contains 'report.sh really prints line 1' '^1:$' 'run it once from the workspace: bash report.sh' -- bash -- report.sh
ck_summary
