#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-alert-anatomy) ---
KEY_Q1_B64="Y20tci0wMTE3"
KEY_Q2_B64="cnVsZS5zZXZlcml0eQ=="
KEY_Q3_B64="Y20tMDMxMS0wMTA3LGNtLTAzMTEtMDEyMSxjbS0wMzExLTAxMzU="
KEY_Q4_B64="MjAzLjAuMTEzLjY2"
KEY_Q5_B64="Y20tMDMxMS0wMTQy"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "alert-CM-A-1024.json"
assert_file_exists "events/raw.jsonl"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains_fixed ".answers.norm" "q2=$K2"
assert_file_contains ".answers.norm" "^q3=$K3$"
assert_file_contains_fixed ".answers.norm" "q4=$K4"
assert_file_contains ".answers.norm" "^q5=$K5$"

ck_summary
