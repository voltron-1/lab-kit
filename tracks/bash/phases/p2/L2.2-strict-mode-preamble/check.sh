#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "e-off.txt" 'backup complete' \
  "pair 1 before-run: bash e-demo.sh > e-off.txt 2>&1 then append the exit= line (command printed in step 1)"
assert_file_contains "e-off.txt" '^exit=0$' \
  "e-off.txt needs the appended exit= line — rerun both step-1 commands"
assert_file_not_contains "e-on.txt" 'backup complete' \
  "pair 1 after-run must use the -e flag: with it, the script dies at cp and never echoes"
assert_file_contains "e-on.txt" '^exit=1$' \
  "e-on.txt — rerun: bash -e e-demo.sh, capture, append the exit= line"
assert_file_contains "u-off.txt" '^cleaning staging/$' \
  "pair 2 before-run: the typo'd variable expands to NOTHING — the captured line ends at the slash"
assert_file_contains "u-off.txt" '^exit=0$' \
  "u-off.txt needs the appended exit= line"
assert_file_contains "u-on.txt" 'unbound variable' \
  "pair 2 after-run must use the -u flag — the typo becomes a named, fatal error"
assert_file_contains "u-on.txt" '^exit=1$' \
  "u-on.txt — rerun: bash -u u-demo.sh, capture, append the exit= line"
assert_file_contains "p-off.txt" '^0$' \
  "pair 3 before-run: wc still prints its answer — capture stdout and stderr together (2>&1)"
assert_file_contains "p-off.txt" '^exit=0$' \
  "p-off.txt — without pipefail the pipeline exits with the LAST command's code"
assert_file_contains "p-on.txt" '^exit=2$' \
  "p-on.txt — rerun with -o pipefail: same output, different verdict (grep's own code)"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — read the preamble as three set calls; what does -o consume?"
assert_file_contains "answers.txt" '^q2=c$' \
  "q2 — which flag is about UNSET variables?"
assert_file_contains "answers.txt" '^q3=a$' \
  "q3 — reread p-off.txt: whose exit code did the pipeline report?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — conditions are exempt: if/while/&&/|| test the command themselves"
ck_summary
