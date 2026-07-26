#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.6}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-killchain) ---
KEY_Q1_B64="d2VhcG9uaXphdGlvbg=="
KEY_Q2_B64="ZXhwbG9pdGF0aW9u"
KEY_Q3_B64="aW5zdGFsbGF0aW9u"
KEY_Q4_B64="dHJpdmlhbA=="
KEY_Q5_B64="c2ltcGxl"
KEY_Q6_B64="YW5ub3lpbmc="
KEY_Q7_B64="aTY="
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"
K6="$(echo "$KEY_Q6_B64" | base64 -d)"
K7="$(echo "$KEY_Q7_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "incident-brief.md"
assert_file_exists "indicators.csv"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q6='
assert_file_contains "answers.txt" '^q7='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains ".answers.norm" "^q2=$K2$"
assert_file_contains ".answers.norm" "^q3=$K3$"
assert_file_contains ".answers.norm" "^q4=$K4$"
assert_file_contains ".answers.norm" "^q5=$K5$"
assert_file_contains ".answers.norm" "^q6=$K6$"
assert_file_contains ".answers.norm" "^q7=$K7$"

ck_summary
