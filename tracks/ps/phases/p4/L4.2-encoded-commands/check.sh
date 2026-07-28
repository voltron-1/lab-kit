#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "decode-enc.ps1" \
  "decode-enc.ps1 — shipped reference decoder must exist"

assert_output_contains "decode-enc.ps1 reveals the benign decoded command" "benign" \
  "run: pwsh -File decode-enc.ps1" -- pwsh -NoProfile -NonInteractive -File decode-enc.ps1

assert_file_exists "audit.md" \
  "audit.md — record the encoded-command audit in audit.md"

assert_file_contains "audit.md" '[Uu][Tt][Ff]-?16|[Uu]nicode' \
  "audit.md — must mention UTF-16LE or Unicode (the actual encoding)"

assert_file_contains "audit.md" '4104|[Ss]cript.?[Bb]lock' \
  "audit.md — must mention 4104 or ScriptBlock logging"

assert_file_contains "audit.md" '[Tt]1027' \
  "audit.md — must cite ATT&CK T1027 (Obfuscation)"

ck_summary
