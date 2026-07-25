#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L3.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L3.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

assert_file_exists "acl-output.txt" \
  "acl-output.txt — reference ACL output file must exist"

assert_file_exists "finding.txt" \
  "finding.txt — record ACL audit finding in finding.txt"

assert_file_contains "finding.txt" 'FullControl|WriteDacl|WriteOwner|GenericAll' \
  "finding.txt — must mention FullControl, WriteDacl, WriteOwner, or GenericAll"

assert_file_contains "finding.txt" '[Pp]riv|[Ee]scalat|[Aa]buse' \
  "finding.txt — must mention Privilege, Escalation, or Abuse"

ck_summary
