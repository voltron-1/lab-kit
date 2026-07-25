#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "health-snapshot.ps1" \
  "health-snapshot.ps1 — reference admin script must exist"

assert_file_exists "tagprobe.ps1" \
  "tagprobe.ps1 — reference probe script must exist"

assert_output_contains "600MB tags CRITICAL" "CRITICAL" \
  "run: pwsh -File tagprobe.ps1" \
  -- pwsh -NoProfile -NonInteractive -File tagprobe.ps1

assert_output_contains "250MB tags WARN" "WARN" \
  "run: pwsh -File tagprobe.ps1" \
  -- pwsh -NoProfile -NonInteractive -File tagprobe.ps1

assert_output_contains "50MB tags OK" "OK" \
  "run: pwsh -File tagprobe.ps1" \
  -- pwsh -NoProfile -NonInteractive -File tagprobe.ps1

assert_file_exists "answers.md" \
  "answers.md — record 10 comprehension answers in answers.md"

matches=0
if [[ -f answers.md ]]; then
  if grep -Eiq '500' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'Quick|Full' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq '[Nn]on.?terminat|-?ErrorAction|Stop' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'ValidateSet|binding|reject' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'WARN' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
  if grep -Eiq 'pscustomobject' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
fi

if [[ "$matches" -ge 4 ]]; then
  pass_msg "answers.md — answered at least 4 of 6 key comprehension checks ($matches/6)"
else
  fail "answers.md — answered only $matches/6 key comprehension checks (expected >= 4)" "Review health-snapshot.ps1 and answer the 10 questions in answers.md"
fi

ck_summary
