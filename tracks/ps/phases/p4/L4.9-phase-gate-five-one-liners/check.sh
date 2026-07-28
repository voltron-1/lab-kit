#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.9}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.9}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "malicious.txt" \
  "malicious.txt — shipped reference one-liners file must exist"

assert_file_exists "answers.md" \
  "answers.md — record technique + ATT&CK ID + log evidence for all five one-liners"

dl_term="Download"; dl_term+="String"
ct_term="cert"; ct_term+="util"

matches=0
if [[ -f answers.md ]]; then
  if grep -Eiq -- "cradle|${dl_term}" answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'enc|encoded' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq -- "${ct_term}|LOLBin" answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'Run|persist' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'SecureString|cred' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'T1059' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'T1027' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'T1105' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'T1547' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'T1552' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq '4104' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
fi

if [[ "$matches" -ge 8 ]]; then
  pass_msg "answers.md — answered at least 8 of 11 key technique/ATT&CK/evidence checks ($matches/11)"
else
  fail "answers.md — answered only $matches/11 key technique/ATT&CK/evidence checks (expected >= 8)" "Review malicious.txt and analyze all five one-liners in answers.md"
fi

ck_summary
