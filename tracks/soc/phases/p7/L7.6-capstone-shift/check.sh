#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L7.6}"
: "${LAB_CHECKLIB:?run this via: lab check soc L7.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "queue.answers"
assert_file_exists "phish.answers"
assert_file_exists "incident.answers"

tr '[:upper:]' '[:lower:]' < queue.answers | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .queue.norm
tr '[:upper:]' '[:lower:]' < phish.answers | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .phish.norm
tr '[:upper:]' '[:lower:]' < incident.answers | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .incident.norm

assert_file_contains_fixed ".queue.norm" "q1=tp"
assert_file_contains_fixed ".queue.norm" "q2=btp"
assert_file_contains_fixed ".queue.norm" "q3=tp"
assert_file_contains_fixed ".queue.norm" "q4=fp"
assert_file_contains_fixed ".queue.norm" "q5=btp"
assert_file_contains_fixed ".queue.norm" "q6=tp"

assert_file_contains_fixed ".phish.norm" "verdict=phish"
assert_file_contains_fixed ".phish.norm" "q_flaw=contradicted"

assert_file_contains_fixed ".incident.norm" "disposition=tp"
assert_file_contains_fixed ".incident.norm" "escalate=y"
assert_file_contains_fixed ".incident.norm" "cite=cm-0311-0201"

ck_summary
