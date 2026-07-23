#!/bin/bash
# TOUR ARTIFACT — production-shaped reference, entirely fictional.
# Read it; nothing in this kit executes it.
#
# feed-refresh — cron wrapper: fetch the threat-intel indicator feed and
# hand it to the sensor, safely.
#
# Installed by the package as /etc/cron.d/feed-refresh:
#
#   17 */4 * * *  root  /usr/local/sbin/feed-refresh >>/var/log/feed-refresh.log 2>&1
#
# Cron gives a job almost no environment (PATH=/usr/bin:/bin, no locale,
# whatever HOME the crontab user has) and will happily start a second copy
# while a slow first copy still runs. Everything unusual in this wrapper
# exists to survive those two facts.

set -euo pipefail

# Cron's PATH won't find systemctl or jq on every distro — pin the full
# search path rather than inherit whatever cron happened to provide.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

readonly FEED_URL="https://feeds.intel.example.test/v2/indicators.json"
readonly FEED_DST="/var/lib/sensor/feeds/indicators.json"
readonly LOCK_FILE="/run/feed-refresh.lock"
readonly MAX_AGE_HOURS=12

TMP_FEED=""

log() {
    printf '%s feed-refresh[%d]: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$$" "$*"
}

cleanup() {
    if [[ -n $TMP_FEED ]]; then
        rm -f "$TMP_FEED"
    fi
}
trap cleanup EXIT

# --- single-instance guard ---------------------------------------------------
# fd 9 holds the lock for the life of the process. -n: don't queue behind a
# stuck run — exit 0 and let the next cron slot try. Exiting 0 (not 1) is
# deliberate: overlap is expected here, and a nonzero exit would page
# whoever watches cron mail for this host.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    log "another run holds ${LOCK_FILE} — exiting"
    exit 0
fi

check_staleness() {
    # Warn (don't fail) when the deployed feed is old — the monitoring side
    # greps this job's log for WARNING to build its alert.
    local age_hours now mtime
    [[ -f $FEED_DST ]] || return 0
    now=$(date +%s)
    mtime=$(stat -c %Y "$FEED_DST")
    age_hours=$(( (now - mtime) / 3600 ))
    if (( age_hours > MAX_AGE_HOURS )); then
        log "WARNING: deployed feed is ${age_hours}h old (threshold ${MAX_AGE_HOURS}h)"
    fi
}

fetch_feed() {
    # mktemp in the DESTINATION directory, not /tmp: the later mv must stay
    # on one filesystem to be an atomic rename (and /tmp may be a tmpfs on
    # a different mount entirely).
    TMP_FEED=$(mktemp "${FEED_DST}.XXXXXX")
    log "fetching ${FEED_URL}"
    curl --fail --silent --show-error --max-time 120 \
        --output "$TMP_FEED" "$FEED_URL"
}

validate_feed() {
    # A 200 response is not a valid feed. An empty or truncated download
    # must never replace a known-good deployed feed.
    jq -e '.indicators | length > 0' "$TMP_FEED" >/dev/null \
        || { log "ERROR: downloaded feed is empty or malformed — keeping current feed"; exit 1; }
}

deploy_feed() {
    chmod 0644 "$TMP_FEED"
    mv -f "$TMP_FEED" "$FEED_DST"
    TMP_FEED=""
    systemctl reload sensor-match.service
    log "feed deployed and sensor-match reloaded"
}

main() {
    check_staleness
    fetch_feed
    validate_feed
    deploy_feed
}

main "$@"
