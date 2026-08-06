#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L2.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L2.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s2-http-tls) ---
KEY_Q1_B64="MjAw"
KEY_Q2_B64="YzIuc3RvbmV3aWNrWy5dZXhhbXBsZQ=="
KEY_Q3_B64="bW96aWxsYS81LjAgKHdpbmRvd3Nwb3dlcnNoZWxsLzUuMSk="
KEY_Q4_B64="cG9zdA=="
KEY_Q5_B64="LQ=="
KEY_Q6_B64="c3Ns"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"
K6="$(echo "$KEY_Q6_B64" | base64 -d)"

assert_file_exists "http.log"
assert_file_exists "ssl.log"
assert_file_exists "answers.txt"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q6='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains_fixed ".answers.norm" "q2=$K2"
assert_file_contains_fixed ".answers.norm" "q3=$K3"
assert_file_contains ".answers.norm" "^q4=$K4$"
assert_file_contains ".answers.norm" "^q5=$K5$"
assert_file_contains ".answers.norm" "^q6=$K6$"

ck_summary
