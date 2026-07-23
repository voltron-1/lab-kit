#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L6.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L6.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^schedule=4$' \
  "schedule — re-read the cron.d line in the header; how many hours pass between runs?"
assert_file_contains "answers.txt" '^lock=flock$' \
  "lock — which tool prevents two copies running at once?"
assert_file_contains "answers.txt" '^lockexit=0$' \
  "lockexit — what exit code does a locked-out run produce?"
assert_file_contains "answers.txt" '^pinpath=cron$' \
  "pinpath — what about the execution environment makes PATH export necessary?"
assert_file_contains "answers.txt" '^tmphome=atomic$' \
  "tmphome — why does mktemp create the download next to FEED_DST instead of /tmp?"
assert_file_contains "answers.txt" '^mustpass=jq$' \
  "mustpass — which tool decides whether the download may replace the deployed feed?"
assert_file_contains "answers.txt" '^failmode=kept$' \
  "failmode — what happens to the deployed feed if the network fetch times out?"
assert_file_contains "answers.txt" '^warnwho=monitoring$' \
  "warnwho — for whom does the staleness WARNING line exist?"

ck_summary
