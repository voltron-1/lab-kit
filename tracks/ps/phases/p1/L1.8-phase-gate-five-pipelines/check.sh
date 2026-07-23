#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L1.8}"
: "${LAB_CHECKLIB:?run this via: lab check ps L1.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "p2.ps1" \
  "p2.ps1 — reference probe script must exist"

assert_output_contains "p2.ps1 outputs 10" "^10$" \
  "run: pwsh -File p2.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p2.ps1

assert_output_contains "p2.ps1 outputs 20" "^20$" \
  "run: pwsh -File p2.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p2.ps1

assert_output_contains "p2.ps1 outputs 30" "^30$" \
  "run: pwsh -File p2.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p2.ps1

assert_output_contains "p2.ps1 outputs 40" "^40$" \
  "run: pwsh -File p2.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p2.ps1

assert_output_contains "p2.ps1 outputs 50" "^50$" \
  "run: pwsh -File p2.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p2.ps1

assert_file_exists "p4.ps1" \
  "p4.ps1 — reference probe script must exist"

assert_output_contains "p4.ps1 outputs CHROME" "CHROME" \
  "run: pwsh -File p4.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p4.ps1

assert_output_contains "p4.ps1 outputs PWSH" "PWSH" \
  "run: pwsh -File p4.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p4.ps1

assert_output_contains "p4.ps1 outputs SSHD" "SSHD" \
  "run: pwsh -File p4.ps1" \
  -- pwsh -NoProfile -NonInteractive -File p4.ps1

assert_file_exists "answers.md" \
  "answers.md — record pipeline predictions in answers.md"

assert_file_contains_fixed "answers.md" "System.Diagnostics.Process" \
  "answers.md — must mention input type System.Diagnostics.Process"

ck_summary
