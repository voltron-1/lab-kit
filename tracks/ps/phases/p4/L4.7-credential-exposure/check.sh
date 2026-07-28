#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "creds-sample.ps1" \
  "creds-sample.ps1 — shipped reference sample must exist"

assert_file_exists "finding.txt" \
  "finding.txt — name >=2 credential exposures, the fix, and the ATT&CK ID"

assert_file_contains "finding.txt" '[Pp][Ll][Aa][Ii][Nn].?[Tt][Ee][Xx][Tt]|AsPlainText' \
  "finding.txt — must mention plaintext or AsPlainText (the in-script-plaintext exposure)"

assert_file_contains "finding.txt" '[Vv]ault|[Ss]ecret [Ss]tore' \
  "finding.txt — must name the fix: secrets belong in a vault or secret store"

assert_file_contains "finding.txt" '[Ee]nv' \
  "finding.txt — must mention the \$Env: exposure (the echoed secret)"

assert_file_contains "finding.txt" 'T1552' \
  "finding.txt — must cite ATT&CK T1552 (Unsecured Credentials)"

ck_summary
