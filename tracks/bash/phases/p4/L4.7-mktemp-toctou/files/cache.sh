#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
process() { wc -c < "$1"; }
tmp=/tmp/acme-cache.$$
if [ ! -e "$tmp" ]; then
  echo "$DATA" > "$tmp"
fi
process "$tmp"
rm -f "$tmp"
