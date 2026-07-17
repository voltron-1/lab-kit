#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally unquoted, to demonstrate what IFS controls
# split-demo.sh — the SAME data, cut three ways, to show what IFS controls.
line="$(cat passwd.line)"
data='a b c'

# 1) default IFS (space/tab/newline): whitespace splits, ':' does not
set -- $data;        printf '1) default IFS, $data  -> argc=%d\n' "$#"

# 2) IFS=':'  — now the colon is the separator, spaces are not
IFS=':' read -ra f <<< "$line"
printf '2) IFS=":" on passwd -> fields=%d first=%s shell=%s\n' "${#f[@]}" "${f[0]}" "${f[-1]}"

# 3) IFS=''  — splitting DISABLED: the whole value stays one word
IFS='' ; set -- $data; printf '3) IFS empty, $data      -> argc=%d\n' "$#"
