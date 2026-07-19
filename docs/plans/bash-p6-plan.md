# Bash Track — Phase 6 Build Plan (Reading Real Deploy Scripts)

## Context

Phase 6 is the bash track's first TOUR phase: five labs, no new syntax, no
destructive content. The learner is handed production-shaped scripts — the
archetypes they already live with (Security Onion-style runbooks, Docker
entrypoints, systemd units, CI scripts, cron jobs) — and graded on whether
they can explain what each does and where the risk sits.

Phase 5 gate confirmed before planning: `planned_execution.md` marks bash p5
`[x]` (6/6 labs), git tag `bash-p5` exists, close-out merge PR #252 at HEAD.
L6.1's spaced-recall questions below are drawn from the six Phase 5
`recap.md` files actually on disk under `tracks/bash/phases/p5/`.

Realism is the design requirement for this phase: every tour artifact reads
like the real thing — idempotency checks, `exec "$@"` handoffs, sandboxing
directives, reproducible-artifact flags — while staying entirely original
and fictional (RFC 2606 `.test` hostnames, no real product code, no secrets).
Every shell artifact is **already verified** `shellcheck -x -S style` clean
(ShellCheck 0.9.0, the repo's sweep invocation) during the plan session; the
build session re-verifies via `tools/shellcheck-all.sh` after the glob
extension below.

## Phase 6 lab list (authoritative, from curriculum map §Phase 6)

| id   | dir name                       | title                                                        | type | gate  | est |
|------|--------------------------------|--------------------------------------------------------------|------|-------|-----|
| L6.1 | `L6.1-so-installer-tour`       | Tour: a Security Onion–style installer/runbook (`so-*`)      | TOUR | false | 18m |
| L6.2 | `L6.2-docker-entrypoint-tour`  | Tour: a Docker `entrypoint.sh` — container-startup idioms    | TOUR | false | 15m |
| L6.3 | `L6.3-systemd-unit-tour`       | Tour: a systemd unit + its `ExecStart` script                | TOUR | false | 18m |
| L6.4 | `L6.4-ci-pipeline-tour`        | Tour: a CI pipeline script — what the runner executes        | TOUR | false | 15m |
| L6.5 | `L6.5-phase-gate-unseen-script`| **Phase gate:** solo tour of an unseen script, cold          | TOUR | true  | 20m |

L6.5's unseen artifact is a **cron wrapper** (the curriculum map's own
open-items section names "a git hook or a cron wrapper" as the candidates;
the cron wrapper exercises more prior-phase concepts: PATH pinning L4.4,
mktemp/atomic-replace L4.7, trap L2.7, strict mode L2.2, exit-code semantics
L1.6/L2.4).

## Design conventions for Phase 6 (departs from Phase 5 where noted)

- **TOUR artifacts are genuine, clean, and NEVER executed.** Unlike p5
  (where `check.sh` runs the reference scripts) and unlike p3/p4 (where
  `files/` holds deliberately broken samples), p6's `files/` scripts are
  correct production-shaped code that nothing in the kit executes — they
  need root paths, systemd, docker, or network that the kit doesn't have.
  Grading is comprehension-only via `answers.txt` + quiz.
- **Accurate banner, per the L5.3 `verify1.sh` lesson.** Each `.sh` artifact
  carries exactly two comment lines under the shebang:
  `# TOUR ARTIFACT — production-shaped reference, entirely fictional.`
  `# Read it; nothing in this kit executes it.`
  (Banner added at build; it's comments only, so the shellcheck-clean status
  verified this session is unaffected.)
- **`shellcheck-all.sh` glob extension.** Add
  `'tracks/*/phases/p6/*/files/*.sh'` beside the existing p5 clause, with a
  comment noting p6 `files/` are real, clean, *never-executed* tour scripts
  — swept because they represent "good production code," not because the
  harness runs them. The `.service` unit file is not `*.sh` and is correctly
  not swept.
- **Fixed-vocabulary answer grammar.** Every comprehension question in
  `lab.md` states its allowed tokens (e.g. "one word from: kept|deleted|
  truncated"), and `check.sh` asserts whole-line anchored, per the L4.2
  anchored-assert lesson: `grep -Eqix 'key=value'` against `answers.txt`
  (case-insensitive value, exact line). No free-text grading.
- **Guided steps run observation commands only** — `grep -n`, `wc -l`,
  `less`, and notably `shellcheck -x -S style files/<artifact>` with expected
  output *zero findings*: after two phases of reading flawed samples, "this
  is what clean looks like" is itself the lesson. Never the artifact itself.
- **Lint hygiene carried from p5:** hint/fail-message strings in `check.sh`
  avoid a bare `/` surrounded by spaces and avoid inline sed-like snippets
  (the `tools/lint-labs.sh` absolute-path false-positive precedent). No
  banned tokens appear in any p6 answer key or hint.
- **L6.5 is a true cold read:** its `lab.md` contains the brief and the
  question sheet only — no walkthrough section. Hint ladder still exists
  (house contract): level 1 = reading strategy, level 2 = per-key nudge,
  level 3 = exact `answers.txt` lines.

## Global build conventions (unchanged from p3/p4/p5)

- One branch + PR + merge per lab: `bash-p6-l6.1` … `bash-p6-l6.5`, then
  `bash-p6-close-out`. Explicit go-ahead before each merge (multi-phase
  gating rule).
- Per lab: build `lab.md`, `meta.json`, `files/`, `check.sh`, `quiz.json`,
  `hints.json`, `recap.md` (+ `recall.json` in L6.1 only). Self-test through
  the real `lab` CLI: fail-before-artifacts → correct `answers.txt` → PASS →
  negative case (one wrong token correctly fails only its assertion).
- Parallel `security-auditor` + `code-reviewer` sub-agent review per lab
  before merge.
- `check.sh` sources the harness via `$LAB_CHECKLIB` (dynamic path), stays
  shellcheck-clean (it's always swept).
- Hint ladder: 3 levels, never the answer first; level 3 gives exact
  `answers.txt` content (house style, see L5.2's `hints.json`).
- Quiz/recall JSON: house schema — `type: "choice"`, options `a/b/c`,
  `answer_b64` base64 of the letter (`a`=`YQ==`, `b`=`Yg==`, `c`=`Yw==`);
  recall questions carry `source` fields.

## Lab entries (build straight from these)

---

### L6.1 — Tour: a Security Onion–style installer/runbook script (`so-*` pattern)

**id/title/type/gate/est:** L6.1 · "Tour: a Security Onion–style
installer/runbook — the `so-*` pattern" · TOUR · gate:false · est 18m
(includes the phase-opener recall quiz).

**meta.json objective:** "Tour a production-shaped installer/runbook script
and name its idempotency check, its validate-before-deploy gate, its atomic
deploy step, and where its operational risk sits."

**TOUR ARTIFACT — `files/so-sensor-refresh.sh` (complete):**

```bash
#!/bin/bash
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
```

**Walkthrough talking points (lab.md guided tour, in this order):**

1. Read the header block first — real runbooks announce their contract
   (idempotent, who calls it, flags) before any code. The `Usage:` line is
   the operator API.
2. `set -euo pipefail` (L2.2 callback) — in an installer this is the
   difference between "stopped at the first broken step" and "kept going and
   half-deployed."
3. The `readonly` constants block is the script's blast-radius map: every
   path it can touch, listed up top. `SERVICES` is an array — `"${SERVICES[@]}"`
   quoting is L1.3/L3.1 discipline.
4. `log`/`die`/`usage` — the standard runbook trio. `tee -a` writes the
   audit trail *and* the operator's terminal; `die` funnels every failure
   through one line format.
5. `trap cleanup EXIT` (L2.7 callback) — why installers trap: a temp file
   staged by a failed run must not poison the next run. Note the guard on
   `TMP_CONF` being non-empty.
6. `config_changed` is the idempotency core: `cmp -s` staged vs deployed;
   `--force` is the documented escape hatch. Trace both return paths.
7. `validate_config` before `deploy_config` — the validate-before-deploy
   gate. Order is the point: nothing on the box changes until the new
   config parses.
8. `deploy_config` — `mktemp` beside the destination (L4.7 callback), then
   atomic `mv`. Ask: why not `cp "$CONF_SRC" "$CONF_DST"` directly? (A
   reader of the half-written file mid-copy.)
9. `restart_services` — the real risk lives here: restarting capture
   services drops sensor visibility for the duration. `systemctl is-active`
   after restart = verify state, don't trust the verb.
10. `main "$@"` at the bottom (house shape since Phase 2) — read order:
    constants → helpers → main, and the `--dry-run` early-exit that makes
    rehearsal safe.

**Comprehension questions (graded, `answers.txt`, fixed vocab shown in lab.md):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `idempotent` | Which function decides whether a re-run has any work to do? | function name | `config_changed` |
| `atomic` | Which single command makes the config deploy atomic? | one word | `mv` |
| `gatekeeper` | Which function guarantees a broken config never reaches /etc? | function name | `validate_config` |
| `verify` | After each restart, what unit state does the script confirm before moving on? | active\|enabled\|masked | `active` |
| `risk` | Where does the operational blast radius sit? | restart\|logging\|argparse | `restart` |
| `trusted` | Which file does the script trust after only a parse check, never a content review? | staged\|deployed\|lockfile | `staged` |

**SHELLCHECK STATUS:** CLEAN — verified this plan session, `shellcheck -x
-S style`, ShellCheck 0.9.0, zero findings (including the trap-referenced
`cleanup`; no SC2317 fires).

**CHECK LOGIC (`check.sh`):** sources `$LAB_CHECKLIB`; asserts `answers.txt`
exists; six anchored asserts `grep -Eqix 'key=token'` (one per row above,
each with its own failure message naming the key, not the answer); then the
quiz. **Does NOT execute `files/so-sensor-refresh.sh`** — it requires root
and `/opt/so`//`/etc/so` paths plus a fictional `so-capture` binary; not
runnable in the kit, and not safe to half-run. Guided steps DO run
`shellcheck -x -S style files/so-sensor-refresh.sh` (expected: no output) —
safe, read-only, and itself a teaching beat.

**QUIZ (quiz.json):**
1. "An idempotent runbook script is one that…" — a) may only run once ·
   **b) is safe to re-run: an unchanged system means a no-op** · c) requires
   --force every time. (`answer_b64: Yg==`)
2. "`config_changed` uses `! cmp -s src dst` — the function succeeds (returns 0)
   when…" — **a) the files differ, i.e. there is work to do** · b) the files
   match · c) cmp itself errors. (`YQ==`)
3. "`systemctl restart` succeeded, yet the script still runs `systemctl
   is-active` — because…" — **a) restart can 'succeed' and the unit can
   still die a moment later; verify state, don't trust the verb** · b)
   is-active is what actually starts the unit · c) --quiet makes it faster.
   (`YQ==`)

**RECAP (recap.md, 3 lines):**
- Runbook shape: parse args → guard → idempotency check → validate → deploy
  atomically → restart → verify; each function is one sentence of the story.
- Idempotency is a cheap comparison up front (cmp staged vs deployed) so
  re-runs are no-ops; --force exists for when that comparison lies.
- Installer risk is rarely syntax — it's the restart's blast radius and the
  trust placed in the staged file it deploys.

**RECALL (recall.json — phase opener, 5 questions from Phase 5 content on disk):**
1. source `bash L5.1`: "`uniq -c` silently undercounts unless its input
   is…" — a) lowercased · **b) sorted, so duplicate lines are adjacent** ·
   c) trimmed of whitespace. (`Yg==`) [from L5.1 recap.md line 2]
2. source `bash L5.2`: "In a `sed` s/// with capture groups, `\1` in the
   replacement is…" — a) line 1 · **b) whatever the first ( ) group
   matched** · c) the first field of the line. (`Yg==`) [L5.2 recap line 3]
3. source `bash L5.3`: "awk's `BEGIN { }` block runs…" — a) once per input
   line · **b) once, before any input is read** · c) whenever a line
   contains BEGIN. (`Yg==`) [L5.3 recap line 3]
4. source `bash L5.4`: "`jq -c` exists to…" — **a) print each result as
   compact single-line JSON — the NDJSON shape** · b) colorize output ·
   c) syntax-check the filter only. (`YQ==`) [L5.4 recap line 1]
5. source `bash L5.5`: "`diff <(cmd1) <(cmd2)` works because process
   substitution…" — a) runs both commands in parallel for speed · **b)
   makes each command's output readable as a filename** · c) merges stdout
   into stderr. (`Yg==`) [L5.5 recap line 1]

---

### L6.2 — Tour: a Docker `entrypoint.sh` — the container-startup idioms

**id/title/type/gate/est:** L6.2 · "Tour: a Docker entrypoint.sh — the
container-startup idioms" · TOUR · gate:false · est 15m.

**meta.json objective:** "Tour a real Docker entrypoint.sh and explain the
defaults block, the first-arg convention, config templating, the bounded
dependency wait, and why the last line must be exec."

**TOUR ARTIFACT — `files/entrypoint.sh` (complete):**

```bash
#!/bin/bash
#
# entrypoint.sh — container entrypoint for the log-relay image
#
# Startup contract, in order:
#   1. Fill in defaults for any tunable the operator didn't set.
#   2. Rewrite $1 if the operator passed only flags (official-image idiom).
#   3. Render the config file from env vars; wait (bounded) for the
#      upstream collector.
#   4. Replace this shell with the real service: exec "$@".
#
# The image's Dockerfile ends with:
#   ENTRYPOINT ["/entrypoint.sh"]
#   CMD ["log-relay", "--config", "/etc/log-relay/relay.conf"]

set -euo pipefail

# --- 1. Defaults ------------------------------------------------------------
# ${VAR:=default} assigns only when VAR is unset or empty, so operator
# overrides (docker run -e RELAY_PORT=6514 ...) always win. The leading :
# is a no-op command that exists just to trigger the expansion.
: "${RELAY_LISTEN_ADDR:=0.0.0.0}"
: "${RELAY_PORT:=6514}"
: "${COLLECTOR_HOST:=collector.internal.test}"
: "${COLLECTOR_PORT:=9000}"
: "${RELAY_LOG_LEVEL:=info}"
: "${STARTUP_TIMEOUT:=30}"

# --- 2. First-argument convention -------------------------------------------
# `docker run image --verbose` replaces CMD entirely, leaving only the flag.
# The official-image idiom: if $1 looks like a flag, put the daemon name
# back in front. `docker run image bash` still drops into a shell untouched.
case "${1:-}" in
    -*) set -- log-relay "$@" ;;
esac

# --- 3. Config templating ---------------------------------------------------
render_config() {
    # Unquoted EOF: this heredoc EXPANDS ${...} — that is the templating.
    # Compare <<'EOF' in L5.5, which suppressed expansion for literal text.
    cat > /etc/log-relay/relay.conf <<EOF
# Generated by entrypoint.sh at container start — do not edit inside the
# running container (changes vanish on restart). Set RELAY_* env vars.
listen ${RELAY_LISTEN_ADDR}:${RELAY_PORT}
forward ${COLLECTOR_HOST}:${COLLECTOR_PORT}
log_level ${RELAY_LOG_LEVEL}
EOF
}

# --- 4. Dependency wait ------------------------------------------------------
wait_for_collector() {
    # /dev/tcp is a bash-ism (the shebang above is load-bearing): opening
    # fd 3 on /dev/tcp/HOST/PORT attempts a TCP connect. The subshell scopes
    # the fd; 2>/dev/null hides retry noise; the until loop bounds the wait.
    local waited=0
    until (exec 3<>"/dev/tcp/${COLLECTOR_HOST}/${COLLECTOR_PORT}") 2>/dev/null; do
        if [[ $waited -ge $STARTUP_TIMEOUT ]]; then
            echo "entrypoint: collector ${COLLECTOR_HOST}:${COLLECTOR_PORT}" \
                 "unreachable after ${STARTUP_TIMEOUT}s — giving up" >&2
            exit 1
        fi
        echo "entrypoint: waiting for collector (${waited}s/${STARTUP_TIMEOUT}s)" >&2
        sleep 2
        waited=$((waited + 2))
    done
}

# Only prepare the environment when we are actually launching the service.
# `docker run image bash` (debugging) skips straight to the exec below.
if [[ ${1:-} == log-relay ]]; then
    render_config
    wait_for_collector
fi

# --- 5. Hand off PID 1 -------------------------------------------------------
# exec replaces this shell with "$@": the service becomes PID 1, receives
# SIGTERM directly on `docker stop`, and no orphaned shell lingers. Without
# exec, the shell keeps PID 1, the signal stops at the shell, and the app
# gets SIGKILLed at the grace-period deadline instead of shutting down clean.
exec "$@"
```

**Walkthrough talking points:**

1. Read the Dockerfile fragment in the header first: ENTRYPOINT + CMD
   composition is why `"$@"` arrives pre-populated — the entrypoint is a
   *wrapper around* CMD, not a replacement for it.
2. The `: "${VAR:=default}"` block is the container's public API — the
   honest, complete list of tunables. The `:` no-op + `:=` assign-default
   idiom (L1.2/L1.4 territory) versus `:-` (substitute-only).
3. `0.0.0.0` as a *default* listen address is the first thing a reviewer
   flags — sensible inside a container network, but the default travels
   wherever the image goes.
4. The `case "${1:-}" in -*)` block (L2.5 callback) is the official-image
   idiom: flags-only invocations get the daemon name restored; `docker run
   image bash` passes through untouched. Note `${1:-}` — under `set -u` a
   bare `$1` with no args would abort (L2.2).
5. `render_config`: an *unquoted* heredoc delimiter is the whole templating
   engine — direct contrast with L5.5's `<<'EOF'`. Config regenerates every
   start; editing it inside the container is futile by design.
6. `wait_for_collector`: `/dev/tcp` is bash, not POSIX — connect the dot to
   L0.3: swap this shebang to `#!/bin/sh` on an Alpine base and this line
   is the breakage. Bounded retry beats both "fail instantly" and "hang
   forever."
7. The `if [[ ${1:-} == log-relay ]]` guard: setup runs only when launching
   the real service — debugging shells skip straight to `exec "$@"`.
8. `exec "$@"` — the most load-bearing word in any entrypoint: PID 1,
   signal delivery, clean `docker stop`. Trace what happens without it
   (shell soaks SIGTERM → SIGKILL at the deadline).

**Comprehension questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `override` | `${RELAY_PORT:=6514}` when RELAY_PORT is already set non-empty does what? | nothing\|overwrites\|errors | `nothing` |
| `prepend` | When $1 starts with a dash, what does the case block prepend? | exact word | `log-relay` |
| `heredoc` | The config heredoc's delimiter is unquoted, so `${...}` inside it… | expands\|literal\|errors | `expands` |
| `probe` | What performs the TCP reachability probe (no curl, no netcat)? | devtcp\|ping\|nmap | `devtcp` |
| `handoff` | Which single word on the last line hands PID 1 to the service? | one word | `exec` |
| `exposure` | Which default would a reviewer question first as the widest network exposure? | listen\|loglevel\|timeout | `listen` |

**SHELLCHECK STATUS:** CLEAN — verified this session (`shellcheck -x -S
style`, 0.9.0, zero findings).

**CHECK LOGIC:** anchored `answers.txt` asserts as L6.1; quiz. **Does NOT
execute the artifact** — it writes `/etc/log-relay/relay.conf` and probes a
`.test` host; container context only. Guided steps run `shellcheck` on it
(expect zero findings) and `grep -n 'exec' files/entrypoint.sh` to locate
the handoff.

**QUIZ:**
1. "Without `exec` on the final line, `docker stop` leads to…" — a) a clean
   shutdown as usual · **b) the shell keeps PID 1, SIGTERM never reaches
   the service, SIGKILL fires at the grace deadline** · c) an immediate
   restart. (`Yg==`)
2. "This entrypoint's shebang must stay `#!/bin/bash` because…" — a) sh has
   no functions · **b) `/dev/tcp` and `[[ ]]` are bash-isms that dash /
   BusyBox sh don't provide** · c) sh can't run in containers. (`Yg==`)
3. "`${VAR:=x}` differs from `${VAR:-x}` in that `:=`…" — **a) also assigns
   VAR, so the default persists for every later use** · b) only raises an
   error · c) never expands anything. (`YQ==`)

**RECAP:**
- An entrypoint is a four-beat contract: default the env vars, render
  config from them, wait (bounded) for dependencies, exec the real process.
- exec is the load-bearing word — the service takes PID 1 and receives
  docker stop's SIGTERM; without it the app dies by SIGKILL after the grace
  period.
- The `${VAR:=default}` block at the top is the container's honest API
  surface — and a 0.0.0.0 default is where a reviewer looks first.

---

### L6.3 — Tour: a systemd unit + its `ExecStart` script

**id/title/type/gate/est:** L6.3 · "Tour: a systemd unit + its ExecStart
script" · TOUR · gate:false · est 18m.

**meta.json objective:** "Read a systemd unit and its ExecStart wrapper
together and state who runs the daemon, what sandbox confines it, and why
the wrapper validates then execs."

**TOUR ARTIFACT 1 — `files/log-relay.service` (complete; not shell — see
shellcheck note):**

```ini
# /etc/systemd/system/log-relay.service
#
# The unit is half the tour: it decides WHO runs the script, WITH WHAT
# environment, and inside WHICH sandbox — before one line of shell runs.

[Unit]
Description=Log relay — receives syslog from sensors, forwards to collector
Documentation=man:log-relay(8)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=logrelay
Group=logrelay
EnvironmentFile=-/etc/default/log-relay
ExecStart=/usr/local/lib/log-relay/start.sh
Restart=on-failure
RestartSec=5s
TimeoutStopSec=20s

# Sandbox: private /tmp, read-only OS, no setuid escalation; the service
# may write only under its own state and log directories.
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/log-relay /var/log/log-relay

[Install]
WantedBy=multi-user.target
```

**TOUR ARTIFACT 2 — `files/start.sh` (complete):**

```bash
#!/bin/bash
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
```

**Walkthrough talking points:**

1. Read the unit before the script — the unit answers who (`User=logrelay`,
   not root), when (`After=`/`Wants=network-online.target`), and inside what
   walls (the sandbox block). The script only answers *what*.
2. `After=` vs `Wants=`: After only *orders*; Wants actually *pulls the
   target in*. Both lines together are the common real-world pair.
3. `EnvironmentFile=-` — the leading dash makes the file optional. This is
   the unit-file cousin of `${VAR:-default}` from L6.2.
4. `Type=simple`: systemd calls the service "started" the moment the
   ExecStart process forks — no readiness protocol. Connects directly to
   why `start.sh` must `exec` (talking point 8).
5. The sandbox block is a security review in eight lines: `ProtectSystem=
   strict` flips the whole OS read-only, `ReadWritePaths` re-opens exactly
   two directories, `NoNewPrivileges` kills setuid escalation. This is the
   unit telling you what a compromise could touch.
6. In `start.sh`: preflight checks (`-x` daemon, `-r` config) fail loud and
   early with actionable messages — under `Restart=on-failure`, a *fast
   clear failure* beats a mysterious crash.
7. The `--check-config` gate exists because of the unit's `Restart=
   on-failure`: without it, a bad config becomes an infinite crashloop
   (throttled by `RestartSec=5s`). Unit and script are one system — each
   line of one explains a line of the other.
8. Final `exec`: MAINPID becomes the daemon itself, so `systemctl stop`'s
   SIGTERM hits the daemon, not a wrapper shell — same lesson as L6.2's
   PID 1, in systemd clothing.
9. Cross-check `SPOOL_DIR` against `ReadWritePaths`: the default spool
   lives under `/var/lib/log-relay` — inside the sandbox's writable set.
   Reviewing means checking that coherence, not each file alone.

**Comprehension questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `runuser` | Which user does the daemon run as? | username | `logrelay` |
| `pullin` | After= only orders — which directive actually pulls network-online.target in? | wants\|requires\|partof | `wants` |
| `envdash` | The leading `-` in `EnvironmentFile=-…` marks the file as… | optional\|readonly\|encrypted | `optional` |
| `execwhy` | start.sh ends in exec so the process systemd supervises as MAINPID is the… | daemon\|wrapper\|shell | `daemon` |
| `writegate` | Under ProtectSystem=strict, which directive re-opens the two writable dirs? | directive, lowercase | `readwritepaths` |
| `crashguard` | Without the --check-config gate, a bad config plus Restart=on-failure produces a… | crashloop\|silence\|rollback | `crashloop` |

**SHELLCHECK STATUS:** `start.sh` CLEAN — verified this session
(`shellcheck -x -S style`, 0.9.0, zero findings). `log-relay.service` is an
INI unit file, not shell — shellcheck N/A by design; optionally run
`systemd-analyze verify` at build if the build box's systemd allows it
[VERIFY-AT-BUILD, non-blocking].

**CHECK LOGIC:** anchored `answers.txt` asserts; quiz. **Does NOT execute
either artifact** — `start.sh` requires `/usr/sbin/log-relay` (fictional
daemon) and the unit requires systemd; neither is runnable in the kit.
Guided steps run `shellcheck` on `start.sh` only (expect clean) plus
`grep -n` navigation of both files.

**QUIZ:**
1. "`Type=simple` means systemd considers the service started…" — **a) as
   soon as the ExecStart process is forked — there is no readiness
   signal** · b) after a built-in health check passes · c) when its port
   opens. (`YQ==`)
2. "`NoNewPrivileges=true` buys you…" — a) faster startup · **b) the
   process tree can never gain privileges via setuid or capabilities, even
   if compromised** · c) automatic user creation. (`Yg==`)
3. "The unit file is half the security review because it decides…" — a)
   code style · **b) who runs the code, with what environment, inside what
   sandbox — before a single script line executes** · c) log formatting.
   (`Yg==`)

**RECAP:**
- A systemd service is two files read as one: the unit decides who/when/
  sandbox; the ExecStart script validates and execs the daemon.
- After= orders, Wants= pulls in; EnvironmentFile=- is optional config; and
  Restart=on-failure without a validate gate is a crashloop generator.
- The hardening block (NoNewPrivileges, ProtectSystem=strict,
  ReadWritePaths) is the unit stating exactly what a compromise of this
  service could touch.

---

### L6.4 — Tour: a CI pipeline script — what the runner actually executes

**id/title/type/gate/est:** L6.4 · "Tour: a CI pipeline script — what the
runner actually executes" · TOUR · gate:false · est 15m.

**meta.json objective:** "Read the script a CI runner actually executes and
identify stage dispatch, failure propagation, artifact reproducibility, and
the secret-exposure surface."

**TOUR ARTIFACT — `files/run-checks.sh` (complete):**

```bash
#!/bin/bash
#
# ci/run-checks.sh — everything the CI runner executes for a merge request.
#
# The pipeline definition (the YAML) is thin on purpose: each job calls this
# script with a stage name, so the exact same commands run on a laptop
# (./ci/run-checks.sh all) and in CI. No logic hides in YAML.
#
# Usage: ci/run-checks.sh {lint|test|build|all}

set -euo pipefail

# Runner-provided context, with local-run fallbacks. CI exports these; on a
# laptop we derive them from git so the script behaves identically.
COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"
ARTIFACT_DIR="${CI_ARTIFACT_DIR:-build/artifacts}"

banner() {
    printf '\n=== %s (%s) ===\n' "$1" "${COMMIT_SHA:0:12}"
}

stage_lint() {
    banner "lint"
    shellcheck -S style scripts/*.sh
    shfmt -d scripts/
}

stage_test() {
    banner "test"
    mkdir -p "$ARTIFACT_DIR"
    ./tests/run-unit-tests.sh --junit "$ARTIFACT_DIR/junit.xml"
}

stage_build() {
    banner "build"
    mkdir -p "$ARTIFACT_DIR"
    # Reproducible tarball: pinned ordering, ownership, and timestamps mean
    # the same commit always produces byte-identical artifacts.
    tar --sort=name --owner=0 --group=0 --mtime='@0' \
        -czf "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz" \
        scripts/ config/
    sha256sum "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz" \
        > "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz.sha256"
}

main() {
    local stage="${1:-}"
    case "$stage" in
        lint)  stage_lint ;;
        test)  stage_test ;;
        build) stage_build ;;
        all)   stage_lint; stage_test; stage_build ;;
        *)
            echo "usage: $0 {lint|test|build|all}" >&2
            exit 2
            ;;
    esac
}

main "$@"
```

**Walkthrough talking points:**

1. The header states the design decision out loud: YAML thin, script thick.
   Reason: the *same commands* run locally and in CI (parity), and a shell
   script can be shellchecked and reviewed — YAML `script:` blobs can't.
2. `set -euo pipefail` in CI (L2.2) is a merge-gate guarantee: a stage that
   fails mid-pipe cannot exit 0 and ship a broken artifact under a green
   build. This one line *is* the pipeline's integrity.
3. The runner contract: `CI_COMMIT_SHA` arrives from the runner's
   environment; `${VAR:-fallback}` derives it from git locally. Same
   default idiom as L6.2, different context.
4. `banner` — CI logs are read by humans at 2am; stage markers with the
   short SHA (`${COMMIT_SHA:0:12}`) are navigation, not decoration.
5. `stage_lint` runs shellcheck/shfmt over the repo's own scripts — the
   L7.5 preview: lint as a merge gate, exactly what this kit's own
   `tools/shellcheck-all.sh` does.
6. `stage_build`'s odd tar flags (`--sort=name --owner=0 --group=0
   --mtime='@0'`) make the artifact *reproducible*: same commit, byte-
   identical tarball, so the sha256 actually means something.
7. The `.sha256` beside the artifact is the trust handoff to the deploy
   side — worthless unless something downstream verifies it (attacker
   perspective: rewrite tarball + checksum together in the same store and
   nobody notices).
8. `case` dispatch (L2.5) with a usage-and-exit-2 default; `all` chains the
   stages in order under the same fail-fast rules.
9. Risk seat: everything this script runs — every test, every lint plugin —
   inherits the runner's full environment, tokens included (L4.4's lesson
   at CI scale). A malicious test file is code execution with those
   secrets.

**Comprehension questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `thinyaml` | Why does the YAML stay thin with all logic in this script? | parity\|speed\|secrets | `parity` |
| `failstop` | Which mechanism makes any failing stage fail the whole job? | pipefail\|banner\|case | `pipefail` |
| `fallback` | With CI_COMMIT_SHA unset (local run), where does COMMIT_SHA come from? | git\|random\|file | `git` |
| `tarflags` | The three unusual tar flags exist to make the artifact… | reproducible\|smaller\|faster | `reproducible` |
| `integrity` | What lets a deploy job verify the tarball is exactly what CI built? | sha256\|junit\|banner | `sha256` |
| `exposure` | On a shared runner, the biggest secret-leak surface this script inherits is the… | env\|tarball\|junit | `env` |

**SHELLCHECK STATUS:** CLEAN — verified this session (`shellcheck -x -S
style`, 0.9.0, zero findings).

**CHECK LOGIC:** anchored `answers.txt` asserts; quiz. **Does NOT execute
the artifact** — it expects `scripts/`, `config/`, `tests/` trees that don't
exist in the lab dir; running it would just fail at lint. Guided steps run
`shellcheck` on it (clean) and `grep -n 'CI_' files/run-checks.sh` to
surface the runner contract.

**QUIZ:**
1. "`set -euo pipefail` matters more in CI than anywhere else because…" —
   a) runners are slow · **b) a stage failing mid-pipe but exiting 0 would
   ship a broken artifact under a green build** · c) the YAML parser
   requires it. (`Yg==`)
2. "The `.sha256` file next to the tarball is only worth anything if…" —
   a) it is gzipped too · **b) something downstream actually verifies it —
   a checksum nobody checks is decoration** · c) it is uploaded twice.
   (`Yg==`)
3. "Runner environment variables are a secret-leak surface because…" — a)
   they are encrypted at rest · **b) every command the script runs inherits
   the full environment, including any CI tokens in it** · c) they slow the
   build down. (`Yg==`)

**RECAP:**
- CI YAML should be thin: the runner ultimately executes a shell script,
  and one script gives local/CI parity plus something you can shellcheck.
- set -euo pipefail is the difference between a red build and a broken
  artifact shipping under a green one.
- Artifacts become trustworthy through reproducible builds (pinned tar
  metadata) plus a checksum the consumer actually verifies.

---

### L6.5 — PHASE GATE: solo tour of an unseen deploy script, answer questions cold

**id/title/type/gate/est:** L6.5 · "Phase gate: solo tour of an unseen
deploy script" · TOUR · **gate:true** · est 20m.

**meta.json objective:** "Given a production cron wrapper you have never
seen, answer cold: schedule, locking, environment assumptions, safe-replace
mechanics, and failure semantics."

**Why a cron wrapper:** the curriculum map's open-items section names "a git
hook or a cron wrapper" as the swappable gate candidates. The cron wrapper
wins on transfer coverage: it forces cold reads of a cron.d schedule line,
`flock` single-instancing, cron's empty-environment problem (PATH pinning —
L4.4), mktemp + atomic rename (L4.7), trap cleanup (L2.7), strict mode
(L2.2), and deliberate exit-code semantics (L1.6/L2.4) — none of which
appeared as a *combination* in L6.1–L6.4, and the cron/flock/exit-0
material appears nowhere in them at all.

**TOUR ARTIFACT — `files/feed-refresh.sh` (complete; learner sees it cold —
lab.md is brief + question sheet only, no walkthrough):**

```bash
#!/bin/bash
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
```

**Gate question sheet (`answers.txt`, 8 keys — all must pass):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `schedule` | How many hours pass between scheduled runs? | a number | `4` |
| `lock` | Which tool prevents two copies running at once? | one word | `flock` |
| `lockexit` | A second copy finding the lock held exits with which code? | a number | `0` |
| `pinpath` | What about the execution environment makes the explicit PATH export necessary? | cron\|sudo\|docker | `cron` |
| `tmphome` | Why does mktemp create the download next to FEED_DST instead of in /tmp? | atomic\|space\|permissions | `atomic` |
| `mustpass` | Which tool decides whether the download may replace the deployed feed? | one word | `jq` |
| `failmode` | curl dies at its 120s timeout — what happens to the currently deployed feed? | kept\|deleted\|truncated | `kept` |
| `warnwho` | The staleness WARNING line exists for whom? | monitoring\|cron\|curl | `monitoring` |

**SHELLCHECK STATUS:** CLEAN — verified this session (`shellcheck -x -S
style`, 0.9.0, zero findings; the trap-referenced `cleanup` raises no
SC2317 under 0.9.0).

**CHECK LOGIC:** anchored asserts on all 8 keys (each failure message names
the key and its reading target — e.g. "schedule: re-read the cron.d line in
the header" — never the answer); quiz 3/3 also required (gate). **Does NOT
execute the artifact** — it would hit the network (`.test` domain, so it
would fail DNS anyway), take a lock in `/run`, and call systemctl; not
runnable in the kit. Because this is the *solo* gate, guided steps are
omitted entirely; `lab.md` = brief (≤10 lines: "you have not seen this
script; read it cold; the header comment is part of the script") + the
question sheet.

**QUIZ:**
1. "`exec 9>file; flock -n 9` holds the lock until…" — **a) fd 9 closes —
   normally when the process exits, however it exits** · b) an explicit
   `flock -u` only · c) nine seconds pass. (`YQ==`)
2. "The wrapper exits 0 when locked out because…" — a) cron requires
   success · **b) overlap is an expected condition, not a failure —
   nonzero would page whoever watches cron mail** · c) flock demands it.
   (`Yg==`)
3. "`mv` is only an atomic replace when…" — a) run as root · **b) source
   and destination are on the same filesystem — which is why mktemp runs
   beside the destination** · c) `-f` is passed. (`Yg==`)

**RECAP:**
- Cron gives you almost no environment and no overlap protection —
  production cron wrappers pin PATH and take a flock before doing anything.
- Download → validate → atomic rename is the universal safe-replace
  pattern: the deployed artifact is either the old version or the new one,
  never partial.
- Exit codes are signaling: lock contention exits 0 (expected), validation
  failure exits 1 (page-worthy), and WARNING lines exist for the monitoring
  grep.

---

## Build-session protocol (execute in this order — gate at each lab per CLAUDE.md)

1. Branch `bash-p6-l6.1` → build L6.1 (incl. `recall.json`) → self-test
   fail-before-artifacts → pass path (6/6 answers + 3/3 quiz + 5/5 recall
   available) → negative case (one wrong token fails only its assert) →
   parallel `security-auditor` + `code-reviewer` → fix findings → PR →
   explicit go-ahead → merge. Repeat for L6.2–L6.5 in order.
2. First lab's branch also carries the `tools/shellcheck-all.sh` glob
   extension (p6 clause + comment) so every subsequent lab is swept from
   the moment it lands.
3. During L6.5's build, draft L7.1's `recall.json` (P7 opener pulling from
   P6) and append it to this plan file — same handoff step the p3→p4
   protocol used.
4. Close-out branch `bash-p6-close-out`: extend `tests/acceptance.sh` with
   a P6 section (5 labs, fabricated pass + negative case each; no
   flawed-sample cases needed — nothing in this phase is destructive or
   broken); fix every stale catalog-count denominator, not just the final
   one — `(11/42)→(11/47)`, `(28/42)→(28/47)`, `(36/42)→(36/47)`,
   `(42/42)→(42/47)`, new `(47/47)` after the P6 block — and the
   "26 unstarted track-phase lines"→"25" count once bash-p6's marker moves
   past `[ ]`; update `planned_execution.md` (marker, NEXT UP, LAST
   SESSION); tag `bash-p6`.

## Verification (how to confirm the built phase is correct)

- `tools/shellcheck-all.sh` clean after the glob extension (sweeps all five
  p6 `check.sh` files AND all five `files/*.sh` tour artifacts; the
  `.service` file correctly ignored).
- `tools/lint-labs.sh` clean (watch the absolute-path heuristic in hint
  strings — precedent says reword rather than exempt).
- Per lab via the real `lab` CLI: `lab start` → check fails before
  `answers.txt` → correct answers → PASS; then the negative case.
- `tests/acceptance.sh` fully green at close-out (expected 5 new labs' pass
  + negative cases on top of the current suite).
- `lab status` shows 47/47 labs registered for the bash track with p6's
  five present; L6.5 marked as gate.

## Open items to confirm at build (not blockers)

- [VERIFY-AT-BUILD] Re-run the shellcheck sweep on the build box — this
  plan's CLEAN statuses were produced with ShellCheck 0.9.0 via stdin; the
  sweep must reproduce zero findings from the committed files.
- [VERIFY-AT-BUILD] Optional `systemd-analyze verify` on
  `log-relay.service` if the WSL2 systemd allows it; manual review is the
  fallback (unit is INI, shellcheck N/A).
- [VERIFY-AT-BUILD] Confirm the `lab` CLI auto-registers `phases/p6/*`
  directories (it globs `phases/*`); confirm `meta.json` `gate:true` renders
  L6.5 as the phase gate in `lab status`.
- [VERIFY-AT-BUILD] Confirm quiz/recall `answer_b64` encodings against the
  harness before commit (letters as base64: a=YQ==, b=Yg==, c=Yw==).
- Banner insertion (the two TOUR-ARTIFACT comment lines) happens at build;
  re-run shellcheck after insertion (comments only — no findings expected).
