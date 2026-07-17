#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# dispatch.sh — look up a file's info; the "action" comes from the caller.
action=$1                             # UNTRUSTED (e.g. from a web form / filename)
target=$2
eval "$action \"$target\""            # eval re-parses the whole string as a command line
