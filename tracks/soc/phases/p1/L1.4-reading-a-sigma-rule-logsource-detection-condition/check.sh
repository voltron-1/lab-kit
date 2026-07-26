#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-sigma-read) ---
KEY_Q1_B64="eQ=="
KEY_Q2_B64="bg=="
KEY_Q3_B64="bg=="
KEY_Q4_B64="bg=="
KEY_Q5_B64="ZmlsdGVyX2JhY2t1cA=="
KEY_Q6_B64="cHdzaC5leGU="
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"
K6="$(echo "$KEY_Q6_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "rule-encoded-powershell.yml"
assert_file_exists "candidates.jsonl"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q6='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains ".answers.norm" "^q2=$K2$"
assert_file_contains ".answers.norm" "^q3=$K3$"
assert_file_contains ".answers.norm" "^q4=$K4$"
assert_file_contains ".answers.norm" "^q5=$K5$"
assert_file_contains_fixed ".answers.norm" "q6=$K6"

ck_summary
