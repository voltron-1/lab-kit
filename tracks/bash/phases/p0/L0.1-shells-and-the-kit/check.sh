#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L0.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L0.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "shell.txt" '^bash$' \
  'step 4 — run: ps -p $$ -o comm= > shell.txt from inside the workspace'
assert_file_contains "sh-target.txt" 'dash$' \
  'step 4 — sh-target.txt must name where the sh symlink resolves: rerun the step-4 readlink redirect'
assert_file_contains "shellcheck.txt" '^version: [0-9]+\.' \
  'step 4 — run: shellcheck --version > shellcheck.txt (step 3 installs the tools)'
assert_file_contains "shfmt.txt" '^v?3\.' \
  'step 4 — run: shfmt --version > shfmt.txt (fails? the step 3 install did not finish)'
ck_summary
