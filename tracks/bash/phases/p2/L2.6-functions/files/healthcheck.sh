#!/usr/bin/env bash
# healthcheck.sh — one function returns a VALUE (echo), the other a VERDICT (return).
count_errors() {
  local n
  n=$(grep -c ERROR "$1")
  echo "$n"
}
is_healthy() {
  local n="$1"
  if (( n == 0 )); then
    return 0
  fi
  return 1
}
n=$(count_errors app.log)
if is_healthy "$n"; then
  echo "status: healthy ($n errors)"
else
  echo "status: degraded ($n errors)"
fi
