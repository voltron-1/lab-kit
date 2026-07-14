#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
