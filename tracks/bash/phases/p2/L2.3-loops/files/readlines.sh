#!/usr/bin/env bash
set -euo pipefail
# readlines.sh — THE way to read a file line by line, byte-safe.
while IFS= read -r line || [ -n "$line" ]; do
  printf '[%s]\n' "$line"
done < "${1:?usage: bash readlines.sh <file>}"
