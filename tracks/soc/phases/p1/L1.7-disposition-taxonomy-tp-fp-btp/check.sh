#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.7}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-dispositions) ---
KEY_Q1_B64="dHA="
KEY_Q1E_B64="Y20tMDMxMS0wMTQy"
KEY_Q2_B64="ZnA="
KEY_Q2E_B64="Y20tMDMxMC0wMDcx"
KEY_Q3_B64="YnRw"
KEY_Q3E_B64="Y20tMDMxMC0wMDE5"
KEY_Q4_B64="YnRw"
KEY_Q4E_B64="Y20tMDMxMC0wMDky"
KEY_Q5_B64="dHA="
KEY_Q5E_B64="Y20tMDMxMS0wMjAx"
KEY_Q6_B64="ZnA="
KEY_Q6E_B64="Y20tMDMxMi0wMjAz"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K1E="$(echo "$KEY_Q1E_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K2E="$(echo "$KEY_Q2E_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K3E="$(echo "$KEY_Q3E_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K4E="$(echo "$KEY_Q4E_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"
K5E="$(echo "$KEY_Q5E_B64" | base64 -d)"
K6="$(echo "$KEY_Q6_B64" | base64 -d)"
K6E="$(echo "$KEY_Q6E_B64" | base64 -d)"

assert_file_exists "answers.txt"

assert_file_contains "answers.txt" '^q1='
assert_file_contains "answers.txt" '^q1e='
assert_file_contains "answers.txt" '^q2='
assert_file_contains "answers.txt" '^q2e='
assert_file_contains "answers.txt" '^q3='
assert_file_contains "answers.txt" '^q3e='
assert_file_contains "answers.txt" '^q4='
assert_file_contains "answers.txt" '^q4e='
assert_file_contains "answers.txt" '^q5='
assert_file_contains "answers.txt" '^q5e='
assert_file_contains "answers.txt" '^q6='
assert_file_contains "answers.txt" '^q6e='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r \t' > .answers.norm

assert_file_contains ".answers.norm" "^q1=$K1$"
assert_file_contains ".answers.norm" "^q1e=($K1E|cm-0311-0143)$"

assert_file_contains ".answers.norm" "^q2=$K2$"
assert_file_contains ".answers.norm" "^q2e=$K2E$"

assert_file_contains ".answers.norm" "^q3=$K3$"
assert_file_contains ".answers.norm" "^q3e=($K3E|cm-0310-0020)$"

assert_file_contains ".answers.norm" "^q4=$K4$"
assert_file_contains ".answers.norm" "^q4e=($K4E|cm-0310-0093|cm-0310-0094)$"

assert_file_contains ".answers.norm" "^q5=$K5$"
assert_file_contains ".answers.norm" "^q5e=$K5E$"

assert_file_contains ".answers.norm" "^q6=$K6$"
assert_file_contains ".answers.norm" "^q6e=($K6E|cm-0312-0204|cm-0312-0205)$"

ck_summary
