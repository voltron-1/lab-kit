#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.8}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^verdict=unsafe$' \
  "would you ever run this? name the verdict"

assert_file_contains "answers.txt" '^search_path=5$' \
  "line 5 puts the current directory ahead of every trusted directory in PATH"
assert_file_contains "answers.txt" '^predictable_temp=6$' \
  "line 6 builds a temp path from nothing but the process id"
assert_file_contains "answers.txt" '^remote_exec=8$' \
  "line 8 chains a second remote script straight into a shell, unread"
assert_file_contains "answers.txt" '^privilege=9$' \
  "line 9 silently claims root privilege with no explanation"
assert_file_contains "answers.txt" '^http_binary=11$' \
  "line 11 downloads a binary over plain HTTP, before anything runs it"
assert_file_contains "answers.txt" '^arg_injection=13$' \
  "line 13 hands an unguarded argument straight to an extraction command with no end-of-options guard"
assert_file_contains "answers.txt" '^obfuscation=16$' \
  "line 16 decodes a blob and hands it straight to a re-parsing builtin, unseen"
assert_file_contains "answers.txt" '^persistence=17$' \
  "line 17 writes itself into a shell rc file so it re-runs on every new shell"
assert_file_contains "answers.txt" '^exfil=18$' \
  "line 18 posts the whole environment to a remote endpoint"

assert_file_contains "answers.txt" '^c2=198\.51\.100\.7$' \
  "extract the indicator of compromise from the decoded blob — the address it downloads from"

# --- proof the learner decoded the blob to a FILE and read it — never piped
# it into a shell. base64 -d is itself a pure, safe decode: check.sh doing
# its own reference decode and diffing against decoded.txt is never unsafe,
# only piping a decode onward ever would be. ---
assert_file_exists "payload.b64" \
  "payload.b64 is missing from your workspace; if it's gone, re-run: lab start bash L4.8 --force"
if [[ -r payload.b64 ]]; then
  base64 -d payload.b64 > .reference-decoded.txt
  assert_cmd_ok "decoded.txt is a genuine decode of payload.b64, not typed-in text" \
    "run: base64 -d payload.b64 > decoded.txt — do not retype or paraphrase the payload" \
    -- diff -q decoded.txt .reference-decoded.txt
fi
ck_summary
