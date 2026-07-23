## BRIEF
In this lab, you tour a production-shaped Security Onion–style installer/runbook script (`files/so-sensor-refresh.sh`).
Nothing in this kit executes the script — it represents system-level infrastructure code requiring root, systemd, and specific network security monitoring (NSM) daemon binaries.
Your job is to audit the script, understand its control flow, and answer the comprehension questions.

## GUIDED STEPS

1. **Read the header block and constants (lines 1–36)**:
   - Notice the script interface and comments: `# TOUR ARTIFACT — production-shaped reference...`.
   - `set -euo pipefail` (Phase 2 callback) halts execution on error or unset variable.
   - Read the `readonly` constants up top — this is the script's blast-radius map.

2. **Understand logging and cleanup traps (lines 138–161)**:
   - `log()` uses `tee -a "$LOG_FILE" >&2` to record audit logs while displaying output.
   - `trap cleanup EXIT` (Phase 2 callback) cleans up any temporary config file staged during a failed run.

3. **Trace the main control flow (lines 214–239)**:
   - `config_changed` (lines 177–183) uses `! cmp -s "$CONF_SRC" "$CONF_DST"` as an idempotency gate so unchanged re-runs are safe no-ops.
   - `validate_config` (lines 184–190) runs `so-capture --test-config "$CONF_SRC"` as a validation gate before touching `/etc`.
   - `deploy_config` (lines 192–202) stages a temp file on destination and renames it via `mv -f` for atomic deployment (`rename(2)`).
   - `restart_services` (lines 203–212) restarts services and verifies health via `systemctl is-active --quiet "$svc"`.

4. **Verify ShellCheck status**:
   ```bash
   shellcheck -x -S style files/so-sensor-refresh.sh
   ```
   *(Expected output: clean, 0 findings)*

5. **Write `answers.txt`** containing six `key=value` lines using the exact allowed vocabulary:
   - `idempotent=config_changed`
   - `atomic=mv`
   - `gatekeeper=validate_config`
   - `verify=active`
   - `risk=restart`
   - `trusted=staged`

6. **Check your work**:
   ```bash
   lab check bash L6.1
   ```
