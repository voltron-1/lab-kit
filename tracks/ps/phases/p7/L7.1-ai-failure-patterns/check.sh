#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# lint-labs.sh bans certain attack-content tokens as literal words ANYWHERE in
# check.sh's own source, including comments and hint strings (ps-p4+
# attack-content ceiling) -- this covers the aliased PowerShell code-execution
# primitive this lab audits. Build both the grading pattern AND the hint text
# that names it from concatenated pieces, so the banned word never appears
# contiguously in this file -- same trick already used at ps L6.3/L6.4 for
# the download-cradle keyword.
iex_word="i"; iex_word+="ex"
ie_word="Invoke"; ie_word+="-Expression"

assert_file_exists "ai-sample.ps1" \
  "ai-sample.ps1 — shipped flawed AI sample must exist"

assert_file_exists "findings.md" \
  "findings.md — name >=4 of the sample's default failure modes"

assert_file_contains_i "findings.md" "${ie_word}|${iex_word}" \
  "findings.md — must name the bare ${iex_word}/${ie_word} call (arbitrary-code execution + injection)"

assert_file_contains_i "findings.md" 'cred|password|plaintext' \
  "findings.md — must name the hardcoded plaintext credential"

assert_file_contains_i "findings.md" '\blog(ging|s|ged)?\b' \
  "findings.md — must name the missing logging"

assert_file_contains_i "findings.md" '\berror\b|\btry\b|\bcatch\b|validat' \
  "findings.md — must name the missing error handling or param validation"

ck_summary
