#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^verdict=malicious$' \
  "would you ever run this? name the verdict"
assert_file_contains "answers.txt" '^flag1=obfuscation$' \
  "the payload is hidden behind base64 plus a re-parsing builtin — name that pattern"
assert_file_contains "answers.txt" '^flag2=remote-download$' \
  "the decoded payload fetches a binary from a remote host"
assert_file_contains "answers.txt" '^flag3=hidden-file$' \
  "the downloaded binary is saved as a dotfile"
assert_file_contains "answers.txt" '^flag4=persistence$' \
  "the decoded payload installs a crontab entry"
assert_file_contains "answers.txt" '^c2=203\.0\.113\.9$' \
  "extract the indicator of compromise — the address the payload downloads from"

# --- proof the learner decoded to a FILE and read it — never piped the
# decode into a shell, never retyped/paraphrased it either. base64 -d is a
# pure decode, exactly the safe operation this lab teaches: it is never
# unsafe for check.sh to perform it here, only to pipe its output onward.
# payload.b64 is a shipped fixture, not something the learner should ever
# need to touch — but guard it anyway so a missing/renamed fixture reports
# a normal graded failure instead of crashing check.sh under set -e. ---
assert_file_exists "payload.b64" \
  "payload.b64 is missing from your workspace — this is a lab fixture; if it's gone, re-run: lab start bash L4.5 --force"
if [[ -r payload.b64 ]]; then
  base64 -d payload.b64 > .reference-decoded.txt
  assert_cmd_ok "decoded.txt is a genuine decode of payload.b64, not typed-in text" \
    "run: base64 -d payload.b64 > decoded.txt — do not retype or paraphrase the payload" \
    -- diff -q decoded.txt .reference-decoded.txt
fi
ck_summary
