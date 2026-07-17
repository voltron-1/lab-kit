#!/usr/bin/env bash
# TEACHING SAMPLE — the SC2030/SC2031 warnings below ARE the lesson
# counter.sh — count three lines two ways. Predict each 'count=' BEFORE running.

count=0
printf 'x\ny\nz\n' | while read -r _; do
  count=$((count + 1))
done
echo "pipe:  count=$count"          # <-- PREDICT this

count=0
while read -r _; do
  count=$((count + 1))
done < <(printf 'x\ny\nz\n')
echo "procsub: count=$count"        # <-- PREDICT this
