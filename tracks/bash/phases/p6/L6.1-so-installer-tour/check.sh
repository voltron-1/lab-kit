#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L6.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L6.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^idempotent=config_changed$' \
  "idempotent — which function decides whether a re-run has work to do?"
assert_file_contains "answers.txt" '^atomic=mv$' \
  "atomic — which single command makes the config deploy atomic?"
assert_file_contains "answers.txt" '^gatekeeper=validate_config$' \
  "gatekeeper — which function guarantees a broken config never reaches /etc?"
assert_file_contains "answers.txt" '^verify=active$' \
  "verify — what unit state does the script confirm after restart?"
assert_file_contains "answers.txt" '^risk=restart$' \
  "risk — where does the operational blast radius sit?"
assert_file_contains "answers.txt" '^trusted=staged$' \
  "trusted — which file does the script trust after a parse check?"

ck_summary
