#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L0.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L0.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_output_contains "pwsh is v7+ and on PATH" '^PowerShell 7\.' \
  "install via the apt repo; snap/dotnet/brew are off the check PATH" \
  -- pwsh --version

assert_file_contains "psversion.txt" 'Core' \
  "psversion.txt — PSEdition must report Core"

assert_file_contains "psversion.txt" 'Unix' \
  "psversion.txt — Platform must report Unix"

assert_file_contains "psversion.txt" '7\.' \
  "psversion.txt — PSVersion must be version 7+"

assert_file_contains_fixed "pssa.txt" "PSScriptAnalyzer" \
  "pssa.txt — run Install-Module PSScriptAnalyzer and save module name"

assert_file_exists "findings.txt" \
  "findings.txt — run Invoke-ScriptAnalyzer on sample.ps1 and save rule findings"

ck_summary
