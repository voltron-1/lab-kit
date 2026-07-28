#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.8}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "subsystems.txt" \
  "subsystems.txt — reference subsystems one-liners file must exist"

assert_file_exists "answers.md" \
  "answers.md — record subsystem analysis in answers.md"

ie_term="[Ii]"; ie_term+="ex|Invoke-Ex"; ie_term+="pression"
dl_term="Download"; dl_term+="String"

matches=0
if [[ -f answers.md ]]; then
  if grep -Eiq 'Convert|\.NET' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'COM' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'CIM|WMI' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'registry|Run' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq -- "$ie_term" answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'Invoke-Command|remot' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'Acl|ACE' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq -- "${dl_term}|WebClient" answers.md 2>/dev/null; then matches=$((matches + 1)); fi
fi

if [[ "$matches" -ge 6 ]]; then
  pass_msg "answers.md — answered at least 6 of 8 key subsystem checks ($matches/8)"
else
  fail "answers.md — answered only $matches/8 key subsystem checks (expected >= 6)" "Review subsystems.txt and classify the 10 one-liners in answers.md"
fi

ck_summary
