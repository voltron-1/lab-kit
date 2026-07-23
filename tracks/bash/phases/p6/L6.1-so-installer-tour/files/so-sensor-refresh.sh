#!/bin/bash
# TOUR ARTIFACT — production-shaped reference, entirely fictional.
# Read it; nothing in this kit executes it.
#
# so-sensor-refresh — apply staged sensor configuration and restart services
#
# Part of the sensor management suite on a Security Onion-style NSM box.
# Idempotent by design: running it twice in a row is safe, and the second
# run is a no-op. Called by the nightly config-management highstate and by
# operators after editing staged config.
#
# Usage: so-sensor-refresh [--force] [--dry-run]

set -euo pipefail

readonly CONF_SRC="/opt/so/conf/staged/sensor.conf"
readonly CONF_DST="/etc/so/sensor.conf"
readonly STATE_DIR="/var/lib/so"
readonly LOG_FILE="/var/log/so/sensor-refresh.log"
readonly SERVICES=(so-capture so-parse so-forward)

FORCE=0
DRY_RUN=0
TMP_CONF=""

log() {
    printf '%s so-sensor-refresh: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" \
        | tee -a "$LOG_FILE" >&2
}

die() {
    log "ERROR: $*"
    exit 1
}

usage() {
    echo "usage: so-sensor-refresh [--force] [--dry-run]" >&2
    exit 2
}

cleanup() {
    # Runs on every exit path (trap EXIT). If deploy_config staged a temp
    # file but the mv never happened, remove it so re-runs start clean.
    if [[ -n $TMP_CONF ]]; then
        rm -f "$TMP_CONF"
    fi
}
trap cleanup EXIT

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)   FORCE=1 ;;
            --dry-run) DRY_RUN=1 ;;
            *)         usage ;;
        esac
        shift
    done
}

require_root() {
    [[ $EUID -eq 0 ]] || die "must run as root"
}

config_changed() {
    # Idempotency check: no work when the staged config already matches the
    # deployed one, unless the operator forces a redeploy.
    [[ $FORCE -eq 1 ]] && return 0
    ! cmp -s "$CONF_SRC" "$CONF_DST"
}

validate_config() {
    # Never deploy a config the capture engine can't parse. --test-config
    # exits nonzero on any syntax error; set -e turns that into a hard stop
    # before anything on the box has changed.
    so-capture --test-config "$CONF_SRC" >/dev/null 2>&1 \
        || die "staged config failed validation: $CONF_SRC"
}

deploy_config() {
    # Stage next to the destination (same filesystem), then mv over it:
    # rename(2) is atomic, so a service reading the config mid-deploy sees
    # either the old file or the new one — never a half-written mix.
    TMP_CONF=$(mktemp "${CONF_DST}.XXXXXX")
    install -m 0640 -o root -g so "$CONF_SRC" "$TMP_CONF"
    mv -f "$TMP_CONF" "$CONF_DST"
    TMP_CONF=""
    log "deployed $CONF_SRC -> $CONF_DST"
}

restart_services() {
    local svc
    for svc in "${SERVICES[@]}"; do
        log "restarting $svc"
        systemctl restart "$svc"
        if ! systemctl is-active --quiet "$svc"; then
            die "$svc did not come back after restart — see: journalctl -u $svc"
        fi
    done
}

main() {
    parse_args "$@"
    require_root
    mkdir -p "$STATE_DIR"

    [[ -f $CONF_SRC ]] || die "staged config missing: $CONF_SRC"

    if ! config_changed; then
        log "config unchanged — nothing to do"
        exit 0
    fi

    validate_config

    if [[ $DRY_RUN -eq 1 ]]; then
        log "dry run: would deploy config and restart: ${SERVICES[*]}"
        exit 0
    fi

    deploy_config
    restart_services
    date '+%s' > "${STATE_DIR}/last-refresh"
    log "refresh complete"
}

main "$@"
