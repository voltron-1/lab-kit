#!/usr/bin/env bash
# REFERENCE SAMPLE — read, decode, and run for real.
set -euo pipefail
grep ' 401 ' access.log \
  | cut -d' ' -f1 \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -1
