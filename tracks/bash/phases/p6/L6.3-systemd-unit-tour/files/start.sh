#!/bin/bash
# TOUR ARTIFACT — production-shaped reference, entirely fictional.
# Read it; nothing in this kit executes it.
#
# start.sh — ExecStart wrapper for log-relay.service
#
# systemd runs this as user 'logrelay' with the environment loaded from
# /etc/default/log-relay (EnvironmentFile). It validates what the daemon
# needs, then execs the daemon so systemd tracks the real process, not a
# wrapper shell.

set -euo pipefail

readonly DAEMON=/usr/sbin/log-relay
readonly CONF="${LOG_RELAY_CONF:-/etc/log-relay/relay.conf}"
readonly SPOOL_DIR="${LOG_RELAY_SPOOL:-/var/lib/log-relay/spool}"

[[ -x $DAEMON ]] || { echo "start.sh: daemon missing or not executable: $DAEMON" >&2; exit 1; }
[[ -r $CONF ]]   || { echo "start.sh: config not readable: $CONF" >&2; exit 1; }

mkdir -p "$SPOOL_DIR"

# Refuse to start with a config the daemon can't parse — otherwise systemd's
# Restart=on-failure would loop a crashing service forever (see the unit).
"$DAEMON" --check-config "$CONF" >/dev/null || {
    echo "start.sh: config failed validation: $CONF" >&2
    exit 1
}

# exec: the daemon replaces this shell, so the MAINPID systemd watches is
# the daemon itself and SIGTERM from `systemctl stop` reaches it directly.
exec "$DAEMON" --config "$CONF" --spool "$SPOOL_DIR" --foreground
