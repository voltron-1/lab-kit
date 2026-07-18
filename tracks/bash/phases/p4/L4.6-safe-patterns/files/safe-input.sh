#!/usr/bin/env bash
# REFERENCE SAMPLE — correct, defensive handling of untrusted input.
set -euo pipefail
PATH=/usr/bin:/bin
name=${1:?usage: safe-input.sh <name>}
case $name in
  *[!a-zA-Z0-9_-]* ) printf 'rejected: %s\n' "$name" >&2; exit 2 ;;
esac
grep -F -- "$name" users.txt
