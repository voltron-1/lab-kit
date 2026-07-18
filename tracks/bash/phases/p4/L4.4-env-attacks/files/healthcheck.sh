#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# healthcheck.sh — installed by the agent; runs from cron as root.
# CWD at run time is /var/spool/acme, which is group-writable.
PATH=.:/usr/local/bin:$PATH
if ps aux | grep -q acme-agent; then
  exit 0
fi
logger "acme-agent not running"
