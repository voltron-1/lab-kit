#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L0.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L0.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s0-fixtures) ---
KEY_Q1_B64="Y20tci0wMTEy"
KEY_Q2_B64="Y20tMDMxMS0wMTA3"
KEY_Q3_B64="YzIuc3RvbmV3aWNrWy5dZXhhbXBsZQ=="
KEY_Q4_B64="d29ya3NwYWNlL3NvYy9sMC4y"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "events.jsonl"
assert_file_exists "alert-sample.json"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains ".answers.norm" "^q2=$K2$"
assert_file_contains_fixed ".answers.norm" "q3=$K3"
assert_file_contains ".answers.norm" "^q4=$K4$"

ck_summary
