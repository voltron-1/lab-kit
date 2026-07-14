#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# L1.8 phase gate: predict all ten numbered lines BEFORE running.
host="web01"
printf '1:%s\n' "$host_id"
printf '2:%s\n' "${host}_id"
hosts=$(cat hosts.txt)
printf '3:%s\n' '*.log'
printf '4:%s\n' "$hosts"
set -- $hosts
printf '5:argc=%s\n' "$#"
printf '6:%s %s\n' *.log
printf '7:%s\n' *.conf
printf '8:%s\n' "$(basename "$(pwd)")"
set -- $(cat hosts.txt)
printf '9:argc=%s\n' "$#"
grep -q FATAL app.log
printf '10:rc=%s\n' "$?"
