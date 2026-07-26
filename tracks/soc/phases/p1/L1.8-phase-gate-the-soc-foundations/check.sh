#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L1.8}"
: "${LAB_CHECKLIB:?run this via: lab check soc L1.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s1-gate-five-alerts) ---
KEY_Q1A_B64="ZW50cmEtc2lnbmlu"
KEY_Q1B_B64="dDExMTAuMDAz"
KEY_Q1C_B64="Yg=="
KEY_Q2A_B64="c3lzbW9u"
KEY_Q2B_B64="dDEwNTkuMDAx"
KEY_Q2C_B64="YQ=="
KEY_Q3A_B64="emVlay1kbnM="
KEY_Q3B_B64="dDEwNzEuMDA0"
KEY_Q3C_B64="Yw=="
KEY_Q4A_B64="d2luLXNlY3VyaXR5"
KEY_Q4B_B64="dDExMzYuMDAx"
KEY_Q4C_B64="YQ=="
KEY_Q5A_B64="bGludXgtYXV0aA=="
KEY_Q5B_B64="dDEwNTMuMDAz"
KEY_Q5C_B64="Yg=="
# --- END GENERATED KEY ---

K1A="$(echo "$KEY_Q1A_B64" | base64 -d)"
K1B="$(echo "$KEY_Q1B_B64" | base64 -d)"
K1C="$(echo "$KEY_Q1C_B64" | base64 -d)"
K2A="$(echo "$KEY_Q2A_B64" | base64 -d)"
K2B="$(echo "$KEY_Q2B_B64" | base64 -d)"
K2C="$(echo "$KEY_Q2C_B64" | base64 -d)"
K3A="$(echo "$KEY_Q3A_B64" | base64 -d)"
K3B="$(echo "$KEY_Q3B_B64" | base64 -d)"
K3C="$(echo "$KEY_Q3C_B64" | base64 -d)"
K4A="$(echo "$KEY_Q4A_B64" | base64 -d)"
K4B="$(echo "$KEY_Q4B_B64" | base64 -d)"
K4C="$(echo "$KEY_Q4C_B64" | base64 -d)"
K5A="$(echo "$KEY_Q5A_B64" | base64 -d)"
K5B="$(echo "$KEY_Q5B_B64" | base64 -d)"
K5C="$(echo "$KEY_Q5C_B64" | base64 -d)"

assert_file_exists "answers.txt"
assert_file_exists "sources-catalog.md"
assert_file_exists "attack-excerpt.json"
assert_file_exists "evidence-menu.md"

assert_file_contains "answers.txt" '^q1a='
assert_file_contains "answers.txt" '^q1b='
assert_file_contains "answers.txt" '^q1c='
assert_file_contains "answers.txt" '^q2a='
assert_file_contains "answers.txt" '^q2b='
assert_file_contains "answers.txt" '^q2c='
assert_file_contains "answers.txt" '^q3a='
assert_file_contains "answers.txt" '^q3b='
assert_file_contains "answers.txt" '^q3c='
assert_file_contains "answers.txt" '^q4a='
assert_file_contains "answers.txt" '^q4b='
assert_file_contains "answers.txt" '^q4c='
assert_file_contains "answers.txt" '^q5a='
assert_file_contains "answers.txt" '^q5b='
assert_file_contains "answers.txt" '^q5c='

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r \t' > .answers.norm

assert_file_contains ".answers.norm" "^q1a=$K1A$"
assert_file_contains_fixed ".answers.norm" "q1b=$K1B"
assert_file_contains ".answers.norm" "^q1c=$K1C$"

assert_file_contains ".answers.norm" "^q2a=$K2A$"
assert_file_contains_fixed ".answers.norm" "q2b=$K2B"
assert_file_contains ".answers.norm" "^q2c=$K2C$"

assert_file_contains ".answers.norm" "^q3a=$K3A$"
assert_file_contains_fixed ".answers.norm" "q3b=$K3B"
assert_file_contains ".answers.norm" "^q3c=$K3C$"

assert_file_contains ".answers.norm" "^q4a=$K4A$"
assert_file_contains_fixed ".answers.norm" "q4b=$K4B"
assert_file_contains ".answers.norm" "^q4c=$K4C$"

assert_file_contains ".answers.norm" "^q5a=$K5A$"
assert_file_contains_fixed ".answers.norm" "q5b=$K5B"
assert_file_contains ".answers.norm" "^q5c=$K5C$"

ck_summary
