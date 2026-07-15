#!/usr/bin/env bash
# triage.sh — route an artifact filename to its handler.
f="${1:-}"
case "$f" in
  "") echo "usage: bash triage.sh <filename>" >&2; exit 2 ;;
  *.log) echo "route: plain log scanner" ;;
  *.json) echo "route: jq pipeline" ;;
  alert_*|ioc_*) echo "route: priority queue" ;;
  *) echo "route: quarantine (unknown type: $f)" ;;
esac
