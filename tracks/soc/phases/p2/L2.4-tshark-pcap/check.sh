#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L2.4}"
: "${LAB_CHECKLIB:?run this via: lab check soc L2.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s2-tshark-pcap) ---
KEY_Q1_B64="Y2RuLnN0b25ld2lja1suXWV4YW1wbGU="
KEY_Q2_B64="MTk4LjUxLjEwMFsuXTIz"
KEY_Q3_B64="Z2V0IC91LnNo"
KEY_Q4_B64="Y3VybC83LjgxLjA="
KEY_Q5_B64="MjAw"
# --- END GENERATED KEY ---

K1="$(echo "$KEY_Q1_B64" | base64 -d)"
K2="$(echo "$KEY_Q2_B64" | base64 -d)"
K3="$(echo "$KEY_Q3_B64" | base64 -d)"
K4="$(echo "$KEY_Q4_B64" | base64 -d)"
K5="$(echo "$KEY_Q5_B64" | base64 -d)"

assert_file_exists "capture.pcap"
assert_file_exists "dns_q.txt"
assert_file_exists "dns_a.txt"
assert_file_exists "http_req.txt"
assert_file_exists "http_status.txt"
assert_file_exists "answers.txt"

# Produced tshark output is RAW tool output, not learner prose - it is NOT
# defanged (contrast with answers.txt q2, which IS). Content-checked on every
# one of the four produced files (not just some of them) so an empty/garbage
# stand-in can't slip an existence-only check; http_req.txt in particular
# checks the real tab-joined 3-column form tshark -T fields -e ... emits, not
# just a bare uri substring a learner could hand-type from lab.md's example.
assert_file_contains_fixed "dns_q.txt" "cdn.stonewick.example"
assert_file_contains_fixed "dns_a.txt" "198.51.100.23"
assert_file_contains_fixed "http_req.txt" $'GET\tcdn.stonewick.example\t/u.sh'  # lint-allow: URI fragment matched against tshark output, not a filesystem path
assert_file_contains "http_status.txt" '^200$'

tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '\r' | sed 's@[[:space:]]*$@@' > .answers.norm

assert_file_contains_fixed ".answers.norm" "q1=$K1"
assert_file_contains_fixed ".answers.norm" "q2=$K2"
assert_file_contains_fixed ".answers.norm" "q3=$K3"
assert_file_contains_fixed ".answers.norm" "q4=$K4"
assert_file_contains ".answers.norm" "^q5=$K5$"

ck_summary
