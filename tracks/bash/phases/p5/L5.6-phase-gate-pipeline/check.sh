#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^stage_grep=filter$' \
  "the grep ' 401 ' stage in top_offender/offender_count — what does it do to the stream?"
assert_file_contains "answers.txt" '^stage_awk=field$' \
  "the trailing awk '{print \$2}' and awk '{print \$1}' calls — what do they pull out of uniq -c's output?"
assert_file_contains "answers.txt" '^stage_diff=procsub$' \
  "diff <(cut ... | sort -u) <(sort ...) — what construct feeds diff its two inputs?"
assert_file_contains "answers.txt" '^stage_sed=herestring$' \
  "the sed -E call redacting top_offender, fed via <<< \"\$top_offender\" — what construct feeds sed its input?"
assert_file_contains "answers.txt" '^stage_jq=reshape$' \
  "jq -n --arg ... — what does it do with the bash variables handed to it?"
assert_file_contains "answers.txt" '^stage_heredoc=report$' \
  "the cat <<REPORT ... REPORT block — what is it for?"
assert_file_contains "answers.txt" '^top_ip=203\.0\.113\.7$' \
  "run ./triage-summary.sh for real — which IP does it report as the top offender?"
assert_file_contains "answers.txt" '^top_count=4$' \
  "run ./triage-summary.sh for real — how many failed logins did the top offender have?"
assert_file_contains "answers.txt" '^ip_status=unknown$' \
  "is 203.0.113.7 in allowed-ips.txt? known or unknown?"
assert_file_contains "answers.txt" '^new_count=1$' \
  "run ./triage-summary.sh for real — how many new IPs does it report?"
assert_cmd_ok "triage-summary.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- triage-summary.sh
assert_output_contains "reports the correct top offender and status" '203\.0\.113\.xxx \(unknown\)' \
  "the script's actual heredoc report should show the redacted top offender and its allowlist status" \
  -- bash -- triage-summary.sh
ck_summary
