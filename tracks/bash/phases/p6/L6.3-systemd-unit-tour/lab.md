## BRIEF
In this lab, you tour a systemd service unit (`files/log-relay.service`) alongside its startup wrapper script (`files/start.sh`).
A systemd unit and its wrapper form an integrated pair: the unit configures identity, ordering, and sandboxing, while the script validates setup and hands off execution to the daemon.
Nothing in this kit executes these artifacts — they require systemd and Linux system paths. Your job is to audit both files together and answer the comprehension questions.

## GUIDED STEPS

1. **Audit the systemd unit (`files/log-relay.service`)**:
   - `User=logrelay` and `Group=logrelay` pin service identity to a unprivileged user.
   - `After=network-online.target` orders startup after the network is up; `Wants=network-online.target` actively pulls the target into the startup transaction.
   - `EnvironmentFile=-/etc/default/log-relay` loads environment variables, where the leading `-` makes the file optional.
   - `ExecStart=/usr/local/lib/log-relay/start.sh` specifies the launcher wrapper.

2. **Analyze the unit sandboxing directives**:
   - `NoNewPrivileges=true` prevents setuid escalation across the entire child process tree.
   - `ProtectSystem=strict` mounts the entire filesystem read-only for the service.
   - `ReadWritePaths=/var/lib/log-relay /var/log/log-relay` explicitly re-opens only two allowed writable paths.

3. **Audit the launcher wrapper (`files/start.sh`)**:
   - `[[ -x $DAEMON ]]` and `[[ -r $CONF ]]` perform fast-fail preflight checks.
   - `"$DAEMON" --check-config "$CONF"` validates configuration syntax *before* launch. Pairing this gate with systemd's `Restart=on-failure` prevents a bad config from triggering an infinite `crashloop`.
   - `exec "$DAEMON" ...` replaces the wrapper shell with the daemon binary, ensuring systemd's `MAINPID` tracks the daemon and `SIGTERM` reaches it directly during `systemctl stop`.

4. **Verify ShellCheck status**:
   ```bash
   shellcheck -x -S style files/start.sh
   ```
   *(Expected output: clean, 0 findings; systemd unit file is INI format)*

5. **Write `answers.txt`** using the exact allowed vocabulary:
   - `runuser=logrelay`
   - `pullin=wants`
   - `envdash=optional`
   - `execwhy=daemon`
   - `writegate=readwritepaths`
   - `crashguard=crashloop`

6. **Check your work**:
   ```bash
   lab check bash L6.3
   ```
