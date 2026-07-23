#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L0.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L0.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "fixed.ps1" \
  "fixed.ps1 — copy broken.ps1 to fixed.ps1 and correct the typo"

assert_file_contains_fixed "fixed.ps1" "\$name" \
  "fixed.ps1 — script must assign and use variable \$name"

assert_file_not_contains "fixed.ps1" "\\\$naem" \
  "fixed.ps1 — remove the typo variable \$naem"

assert_output_contains "fixed.ps1 greets the analyst" "Hello, analyst" \
  "run: pwsh -File fixed.ps1 to test your output" \
  -- pwsh -NoProfile -NonInteractive -File fixed.ps1

location_hint="location.txt — run: pwd > location.txt while inside workspace/ps/L0.2"
if [[ -f location.txt ]]; then
  recorded_dir="$(realpath -m -- "$(cat location.txt)")"
  workspace_dir="$(realpath -- "$LAB_WORKSPACE")"
  if [[ "$recorded_dir" == "$workspace_dir" ]]; then
    pass_msg "location.txt was written from inside the workspace"
  else
    fail "location.txt was written from inside the workspace" "$location_hint"
  fi
else
  fail "location.txt missing" "$location_hint"
fi

ck_summary
