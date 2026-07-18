#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# lookup.sh — print the greeting line for a named user.
name=$1                                        # UNTRUSTED (e.g. from a web form)
line=$(bash -c "grep ^$name: greetings.txt")   # $name spliced unquoted into a shell string, re-parsed
echo "$line"
