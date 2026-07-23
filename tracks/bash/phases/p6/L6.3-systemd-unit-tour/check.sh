#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L6.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L6.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^runuser=logrelay$' \
  "runuser — which user does the daemon run as?"
assert_file_contains "answers.txt" '^pullin=wants$' \
  "pullin — which directive pulls network-online.target in?"
assert_file_contains "answers.txt" '^envdash=optional$' \
  "envdash — what does the leading dash in EnvironmentFile=-... mark the file as?"
assert_file_contains "answers.txt" '^execwhy=daemon$' \
  "execwhy — what process does systemd supervise as MAINPID because start.sh uses exec?"
assert_file_contains "answers.txt" '^writegate=readwritepaths$' \
  "writegate — which directive re-opens writable directories under ProtectSystem=strict?"
assert_file_contains "answers.txt" '^crashguard=crashloop$' \
  "crashguard — what does --check-config prevent when paired with Restart=on-failure?"

ck_summary
