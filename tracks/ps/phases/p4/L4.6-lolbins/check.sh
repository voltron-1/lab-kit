#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "finding.txt" \
  "finding.txt — name a LOLBin, the parent-child detection tell, and an ATT&CK ID"

lb1="[Cc]ert"; lb1+="util"
lb2="[Mm]s"; lb2+="hta"
lb3="[Rr]und"; lb3+="ll32"
lb4="[Rr]egsvr"; lb4+="32"
lolbin_pattern="$lb1|$lb2|$lb3|$lb4"

assert_file_contains "finding.txt" "$lolbin_pattern" \
  "finding.txt — must name a LOLBin used for download or proxy execution"

assert_file_contains "finding.txt" '[Pp]arent.{0,60}[Cc]hild|[Cc]hild.{0,60}[Pp]arent' \
  "finding.txt — must state the parent-child process-chain detection tell, not just mention 'process' in passing"

assert_file_contains "finding.txt" '[Tt]1218|[Tt]1105' \
  "finding.txt — must cite ATT&CK T1218 (System Binary Proxy Execution) or T1105 (Ingress Tool Transfer)"

ck_summary
