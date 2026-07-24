#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L2.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L2.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "forloop.ps1" \
  "forloop.ps1 — reference probe script must exist"

assert_output_contains "forloop outputs 1" "^1$" \
  "run: pwsh -File forloop.ps1" \
  -- pwsh -NoProfile -NonInteractive -File forloop.ps1

assert_output_contains "forloop outputs 2" "^2$" \
  "run: pwsh -File forloop.ps1" \
  -- pwsh -NoProfile -NonInteractive -File forloop.ps1

assert_output_contains "forloop outputs 3" "^3$" \
  "run: pwsh -File forloop.ps1" \
  -- pwsh -NoProfile -NonInteractive -File forloop.ps1

assert_file_exists "foreachstmt.ps1" \
  "foreachstmt.ps1 — reference probe script must exist"

assert_output_contains "foreachstmt outputs 3" "^3$" \
  "run: pwsh -File foreachstmt.ps1" \
  -- pwsh -NoProfile -NonInteractive -File foreachstmt.ps1

assert_output_contains "foreachstmt outputs 5" "^5$" \
  "run: pwsh -File foreachstmt.ps1" \
  -- pwsh -NoProfile -NonInteractive -File foreachstmt.ps1

assert_output_contains "foreachstmt outputs 7" "^7$" \
  "run: pwsh -File foreachstmt.ps1" \
  -- pwsh -NoProfile -NonInteractive -File foreachstmt.ps1

assert_file_exists "dowhile.ps1" \
  "dowhile.ps1 — reference probe script must exist"

assert_output_contains "dowhile outputs 5" "^5$" \
  "run: pwsh -File dowhile.ps1" \
  -- pwsh -NoProfile -NonInteractive -File dowhile.ps1

assert_file_exists "prediction.txt" \
  "prediction.txt — record loop predictions in prediction.txt"

assert_file_contains "prediction.txt" '^forloop=1 2 3$' \
  "prediction.txt — line forloop=1 2 3"

assert_file_contains "prediction.txt" '^foreachstmt=3 5 7$' \
  "prediction.txt — line foreachstmt=3 5 7"

assert_file_contains "prediction.txt" '^dowhile=5$' \
  "prediction.txt — line dowhile=5"

ck_summary
