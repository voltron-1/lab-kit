#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "finding.txt" \
  "finding.txt — name >=3 LOLBins, the parent-child detection tell, and an ATT&CK ID"

lb1="cert"; lb1+="util"
lb2="ms"; lb2+="hta"
lb3="rund"; lb3+="ll32"
lb4="regsvr"; lb4+="32"
lolbin_pattern="$lb1|$lb2|$lb3|$lb4"

assert_file_contains "finding.txt" "$lolbin_pattern" \
  "finding.txt — must name a LOLBin used for download or proxy execution"

assert_file_contains "finding.txt" '[Pp]arent|child|process' \
  "finding.txt — must mention the parent-child (process) detection tell"

assert_file_contains "finding.txt" 'T1218|T1105' \
  "finding.txt — must cite ATT&CK T1218 (System Binary Proxy Execution) or T1105 (Ingress Tool Transfer)"

ck_summary
