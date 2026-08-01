#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# PSScriptAnalyzer is graded from a learner-produced FILE, never re-run live here
# (ps-p01 sec2/sec3a): under this check-runner's env -i HOME redirect, a live
# Invoke-ScriptAnalyzer sees an empty module path and finds nothing, which would
# report a flawed script as clean -- the exact wrong-reason pass this avoids.

assert_file_exists "candidate.ps1" \
  "candidate.ps1 — shipped PSScriptAnalyzer sample must exist"

assert_file_exists "pssa.txt" \
  "pssa.txt — run Invoke-ScriptAnalyzer on candidate.ps1 and capture the output"

# Column-header check, not a specific rule name (exact rule identifiers are
# version-dependent -- ps-p7-plan.md sec7). RuleName+Severity together are only
# present in genuine Select-Object-shaped PSSA output, not a hand-typed stub.
assert_file_contains_i "pssa.txt" 'RuleName' \
  "pssa.txt — must contain real Invoke-ScriptAnalyzer output (a RuleName column)"

assert_file_contains_i "pssa.txt" 'Severity' \
  "pssa.txt — must contain real Invoke-ScriptAnalyzer output (a Severity column)"

assert_file_exists "ci-step.yml" \
  "ci-step.yml — draft a CI step that fails the build on any PSSA Error/Warning"

assert_file_contains_i "ci-step.yml" 'Invoke-ScriptAnalyzer|PSScriptAnalyzer' \
  "ci-step.yml — must invoke PSScriptAnalyzer"

assert_file_contains_i "ci-step.yml" '\bfail\b|\bexit\b|\berror\b|\bwarning\b' \
  "ci-step.yml — must fail/exit the build on an Error or Warning finding"

assert_file_exists "notes.md" \
  "notes.md — name the cross-track equivalent (bash's ShellCheck)"

assert_file_contains_i "notes.md" 'shellcheck' \
  "notes.md — must name ShellCheck as the bash-track equivalent"

ck_summary
