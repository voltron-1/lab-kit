#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-log-anatomy) ---
KEY_Q1_B64="MjAyNi0wMy0xMHQxMzo1OTo1N3o="
KEY_Q2_B64="ZTIsZTEsZTQsZTMsZTU="
KEY_Q3_B64="c291cmNlLmlw"
KEY_Q4_B64="ZXZlbnQuY29kZQ=="
KEY_Q5_B64="LTA1OjAw"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "ecs.jsonl"
assert_file_exists "raw-syslog.txt"
assert_file_exists "windows-raw.json"
assert_file_exists "events-map.csv"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains ".answers.norm" "^q2=$K2$"
assert_file_contains_fixed ".answers.norm" "q3=$K3"
assert_file_contains_fixed ".answers.norm" "q4=$K4"
assert_file_contains ".answers.norm" "^q5=$K5$"

ck_summary
