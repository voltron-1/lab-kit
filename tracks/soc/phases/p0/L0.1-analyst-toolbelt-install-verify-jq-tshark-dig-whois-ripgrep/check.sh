#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L0.1}"
: "${LAB_CHECKLIB:?run this via: lab check soc L0.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- BEGIN GENERATED KEY (genevidence: s0-fixtures) ---
KEY_K_JQ_USER_B64="bS5yZXllcw=="
KEY_K_TSHARK_QNAME_B64="Y29wcGVybWluZS5leGFtcGxl"
KEY_K_RG_MARKER_B64="Q00tVE9PTEJFTFQtN0M0Mg=="
# --- END GENERATED KEY ---

K_JQ_USER="$(echo "$KEY_K_JQ_USER_B64" | base64 -d)"
K_TSHARK_QNAME="$(echo "$KEY_K_TSHARK_QNAME_B64" | base64 -d)"
K_RG_MARKER="$(echo "$KEY_K_RG_MARKER_B64" | base64 -d)"

assert_cmd_ok "jq responds" "apt-get install jq" -- jq --version
assert_cmd_ok "tshark responds" "apt-get install tshark" -- tshark --version
assert_cmd_ok "dig responds" "apt-get install dnsutils" -- dig -v
assert_cmd_ok "whois responds" "apt-get install whois" -- whois --version
assert_cmd_ok "rg responds" "apt-get install ripgrep" -- rg --version

assert_file_exists "toolcheck.txt"
assert_file_contains "toolcheck.txt" 'jq-[0-9]'
assert_file_contains "toolcheck.txt" 'TShark'
assert_file_contains "toolcheck.txt" 'DiG [0-9]'
assert_file_contains "toolcheck.txt" 'Version [0-9]'
assert_file_contains "toolcheck.txt" 'ripgrep [0-9]'

assert_file_contains_fixed "jq_out.txt" "$K_JQ_USER"
assert_file_contains_fixed "tshark_out.txt" "$K_TSHARK_QNAME"
assert_file_contains_fixed "rg_out.txt" "$K_RG_MARKER"

ck_summary
