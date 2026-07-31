#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# lint-labs.sh bans certain attack-content tokens as literal words ANYWHERE in
# check.sh's own source, including comments and hint strings (ps-p4+
# attack-content ceiling). Build the grading pattern from concatenated
# pieces so the banned word never appears contiguously -- same trick as L7.1/L7.2.
iex_word="i"; iex_word+="ex"
ie_word="Invoke"; ie_word+="-Expression"

assert_file_exists "checklist.md" \
  "checklist.md — write a >=6-item review checklist covering the L7.1 failure set"

assert_file_contains_i "checklist.md" "${iex_word}|${ie_word}" \
  "checklist.md — must have an item checking for the bare ${iex_word}/${ie_word} call"

assert_file_contains_i "checklist.md" '\btry\b|\bcatch\b|ErrorAction' \
  "checklist.md — must have an item checking for try/catch or -ErrorAction Stop"

assert_file_contains_i "checklist.md" '\blog(ging|s|ged)?\b' \
  "checklist.md — must have an item checking that logging is on"

assert_file_contains_i "checklist.md" 'PSScriptAnalyzer|PSSA' \
  "checklist.md — must name PSScriptAnalyzer/PSSA as the automated backstop item"

assert_file_contains_i "checklist.md" 'cred|secret' \
  "checklist.md — must have an item checking for hardcoded creds/secrets"

ck_summary
