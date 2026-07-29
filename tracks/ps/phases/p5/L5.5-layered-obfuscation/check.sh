#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

# tools/lint-labs.sh scans this file for attack-token names case-insensitively,
# so the name is never written contiguously here.
dl_term="Download"; dl_term+="String"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "peel.ps1" \
  "peel.ps1 — shipped reference probe must exist"

# peel.ps1 is read-only reference material, and this grader executes it. Byte
# identity is the whole integrity check: it rejects a gutted stub that hardcodes
# the expected output, and it rejects a probe edited to actually run a peeled
# layer, without needing to enumerate PowerShell's invocation primitives.
assert_file_unmodified "peel.ps1" "$lab_dir/files/peel.ps1" \
  "peel.ps1 — peel and PRINT each layer, never run one; restore the shipped file"

# Execute the probe only once it is proven unmodified. A phase whose whole lesson
# is decode-to-read-never-to-run must not have its own grader be the thing that runs
# a tampered probe -- so a modified peel.ps1 is reported, never executed.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "the layered payload reconstructs to a cradle" "$dl_term" \
    "run: pwsh -File peel.ps1" -- pwsh -NoProfile -NonInteractive -File peel.ps1

  assert_output_contains "the reconstructed cradle names the fake C2 host" "fake-c2" \
    "run: pwsh -File peel.ps1" -- pwsh -NoProfile -NonInteractive -File peel.ps1
else
  fail "peel.ps1 not run — it no longer matches the shipped probe" \
    "restore the shipped peel.ps1, then re-run: lab check ps L5.5"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record the fully peeled plaintext you read"

assert_file_contains_i "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the reconstructed cradle"

assert_file_exists "layers.txt" \
  "layers.txt — name each obfuscation layer you peeled, outermost first"

assert_file_contains_i "layers.txt" "base64" \
  "layers.txt — must name the outer layer (base64)"

assert_file_contains_i "layers.txt" "revers" \
  "layers.txt — must name the inner layer (string reversal)"

ck_summary
