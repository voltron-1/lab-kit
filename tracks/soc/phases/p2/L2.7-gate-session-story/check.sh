#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L2.7}"
: "${LAB_CHECKLIB:?run this via: lab check soc L2.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s2-gate-session) ---
KEY_Q1_B64="YzIuc3RvbmV3aWNrWy5dZXhhbXBsZQ=="
KEY_Q2_B64="MjAzLjAuMTEzWy5dNjY="
KEY_Q3_B64="YzIuc3RvbmV3aWNrWy5dZXhhbXBsZQ=="
KEY_Q4_B64="MzAw"
KEY_Q5_B64="MTAuMjAuMzBbLl0xMDc="
KEY_Q6_B64="MTAuMjAuMzFbLl0xMTI="
KEY_Q7_B64="L3Uuc2g="
KEY_Q8_B64="Y20tMDMxMS0wNTAw"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"
K6="$(echo "$KEY_Q6_B64" | base64 -d)"
K7="$(echo "$KEY_Q7_B64" | base64 -d)"
K8="$(echo "$KEY_Q8_B64" | base64 -d)"

assert_file_exists "zeek/conn.log"
assert_file_exists "zeek/dns.log"
assert_file_exists "zeek/http.log"
assert_file_exists "zeek/ssl.log"
assert_file_exists "capture.pcap"
assert_file_exists "answers.txt"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q6='
assert_file_contains "answers.txt" '^q7='
assert_file_contains "answers.txt" '^q8='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm

assert_file_contains_fixed ".answers.norm" "q1=$K1"
assert_file_contains_fixed ".answers.norm" "q2=$K2"
assert_file_contains_fixed ".answers.norm" "q3=$K3"
assert_file_contains ".answers.norm" "^q4=$K4$"
assert_file_contains_fixed ".answers.norm" "q5=$K5"
assert_file_contains_fixed ".answers.norm" "q6=$K6"
assert_file_contains_fixed ".answers.norm" "q7=$K7"  # lint-allow: URI fragment matched against a learner answer, not a filesystem path
assert_file_contains ".answers.norm" "^q8=$K8$"

ck_summary
