# Telemetry Sources Catalog

| Slug | Telemetry Plane | Description & Primary Index | Telltale Fields |
|---|---|---|---|
| `zeek-conn` | Network | Network connection state & transport metrics (`index=zeek_conn`) | `source.ip`, `destination.ip`, `destination.port`, `network.bytes` |
| `zeek-dns` | Network | DNS queries & responses (`index=zeek_dns`) | `dns.question.name`, `dns.question.type`, `dns.response_code` |
| `win-security` | Host | Windows Security Audit Event Log (`index=win_security`) | `event.code` (e.g. 4624, 4625, 4720, 4732), `winlog.logon.type`, `user.name` |
| `sysmon` | Host | Microsoft Sysmon process & system telemetry (`index=sysmon`) | `event.code` (1=Process, 3=Net, 11=File, 13=Registry), `process.command_line` |
| `linux-auth` | Host | Linux Authentication & PAM Syslog (`index=linux_auth`) | `sshd`, `sudo`, `pam_unix`, `crontab`, `systemd` |
| `entra-signin` | Identity | Microsoft Entra ID Cloud Sign-in Logs (`index=entra_signin`) | `user`, `app`, `mfa`, `result`, `source.ip` |
