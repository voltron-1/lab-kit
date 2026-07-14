#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L0.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L0.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt" 'step 13 — record q1=<letter> through q4=<letter>, one per line, no spaces around ='
assert_file_contains "answers.txt" '^q1=b$' 'q1 — sh-target.txt already names the interpreter a ./deploy.sh exec would get'
assert_file_contains "answers.txt" '^q2=b$' 'q2 — what shell answers to sh inside a Debian or Alpine container?'
assert_file_contains "answers.txt" '^q3=b$' 'q3 — the SC3010 line in sc-out.txt answers this verbatim'
assert_file_contains "answers.txt" '^q4=c$' 'q4 — honest means shebang and syntax agree; count the directions that restore agreement'
assert_file_contains "dash-run.txt" 'not found' 'step 8 — dash deploy.sh > dash-run.txt 2>&1 must capture the line-4 [[ error'
assert_file_contains "dash-run.txt" 'Bad substitution' 'step 8 — the line-7 error belongs in dash-run.txt too (the 2>&1 does that)'
assert_file_contains "bash-run.txt" 'deploying to PROD' 'step 9 — bash deploy.sh > bash-run.txt 2>&1'
assert_file_contains "sh-target.txt" 'dash$' 'step 10 — readlink -f the sh symlink, redirected into sh-target.txt (exact command in lab.md)'
assert_file_contains "sc-out.txt" 'SC3010' 'step 11 — shellcheck -s sh deploy.sh > sc-out.txt 2>&1 || true — the -s sh flag is the point'
ck_summary
