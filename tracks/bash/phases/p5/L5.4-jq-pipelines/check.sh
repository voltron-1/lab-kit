#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^flag_c=compact$' \
  "the -c flag on jq — what shape does it print each JSON object in?"
assert_file_contains "answers.txt" '^key_style=literal$' \
  "\"source.ip\" as an object-construction key — is the dot a nested path or part of one literal string key?"
assert_file_contains "answers.txt" '^line9=derived$' \
  "event.outcome isn't copied from the input — it's computed. What kind of field is that?"
assert_file_contains "answers.txt" '^test_fn=regex$' \
  "test(\"failed\") inside the if — what kind of match does jq's test() perform?"
assert_cmd_ok "reshape-ecs.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- reshape-ecs.sh
assert_output_contains "alice's two failed logins reshape correctly" '"event.outcome":"failure"' \
  "the script's actual output should mark alice's login_failed events as a failure outcome" \
  -- bash -- reshape-ecs.sh
assert_output_contains "bob's success reshapes correctly" '"event.outcome":"success"' \
  "the script's actual output should mark bob's login_success event as a success outcome" \
  -- bash -- reshape-ecs.sh
ck_summary
