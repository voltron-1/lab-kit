## BRIEF
In this lab, you tour a real container startup script (`files/entrypoint.sh`).
Container entrypoints wrap application binaries to handle configuration templating, default environment variables, dependency readiness checks, and signal propagation.
Nothing in this kit executes the script — it runs inside container environments. Your job is to audit the script, trace its startup contract, and answer the comprehension questions.

## GUIDED STEPS

1. **Read the Dockerfile header fragment and defaults (lines 1–37)**:
   - Notice the `# TOUR ARTIFACT...` header banner.
   - Look at `: "${VAR:=default}"` — the `:` no-op combined with `${VAR:=default}` assigns default values only when unset or empty, establishing the container's public configuration API.
   - `0.0.0.0` as `RELAY_LISTEN_ADDR` opens network exposure across all container interfaces.

2. **Understand the first-argument convention (lines 39–35)**:
   - `case "${1:-}" in -*) set -- log-relay "$@" ;; esac` restores the binary name if `docker run` was passed flags only.
   - Under `set -u`, `${1:-}` prevents an unbound variable crash when `$1` is missing.

3. **Trace config templating and dependency waiting (lines 38–423)**:
   - `render_config()` uses an *unquoted* heredoc `cat > /etc/... <<EOF` to expand environment variables into config file content.
   - `wait_for_collector()` uses `/dev/tcp/${COLLECTOR_HOST}/${COLLECTOR_PORT}` for a pure-bash socket check, bounded by `STARTUP_TIMEOUT`.
   - The `if [[ ${1:-} == log-relay ]]` block runs setup only when starting the main daemon (skipping setup for `docker run image bash` debug sessions).

4. **Examine PID 1 handoff (line 430)**:
   - `exec "$@"` replaces the shell process with the daemon process.
   - Replacing shell with daemon makes the daemon PID 1 so it receives `SIGTERM` directly during `docker stop`. Without `exec`, the shell remains PID 1 and ignores `SIGTERM`, causing `docker stop` to forcibly `SIGKILL` the container.

5. **Verify ShellCheck status**:
   ```bash
   shellcheck -x -S style files/entrypoint.sh
   ```
   *(Expected output: clean, 0 findings)*

6. **Write `answers.txt`** using the exact allowed vocabulary:
   - `override=nothing`
   - `prepend=log-relay`
   - `heredoc=expands`
   - `probe=devtcp`
   - `handoff=exec`
   - `exposure=listen`

7. **Check your work**:
   ```bash
   lab check bash L6.2
   ```
