#!/usr/bin/env bash
# REFERENCE SAMPLE — read, decode, and run for real.
set -euo pipefail
sed -E \
  -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[IP-REDACTED]/g' \
  -e 's/^\[IP-REDACTED\] - - \[([^]]+)\] "([A-Z]+) ([^ ]+) [^"]+" ([0-9]{3}) .*/ts=\1 method=\2 path=\3 status=\4/' \
  access.log
