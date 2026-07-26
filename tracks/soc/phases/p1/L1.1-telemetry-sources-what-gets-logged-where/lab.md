## BRIEF
SOC analysts triage telemetry across three core observability planes: **network** (conversations, DNS queries, packet statistics), **endpoint** (processes, command lines, local/domain logins), and **identity** (cloud app sign-ins, MFA status, SSO).
In this lab, you inspect six staged Coppermine telemetry files (`telemetry/a` through `f`) and map eight security observation statements to the exact telemetry source that recorded them.

## GUIDED STEPS

1. **Examine the six telemetry sources in `telemetry/`**:
   Inspect the headers and fields of each telemetry source:
   - `telemetry/a-zeek-conn.log` (Network: Zeek TCP/UDP connection summaries, duration, byte counts)
   - `telemetry/b-zeek-dns.log` (Network: Zeek DNS queries, record types, response IPs)
   - `telemetry/c-windows-security.json` (Endpoint: Windows Security events 4624/4625 logons on DC01)
   - `telemetry/d-sysmon.json` (Endpoint: Sysmon Event ID 1 process creation and command lines)
   - `telemetry/e-auth.log` (Endpoint/Server: Linux SSH authentication log on WEB01)
   - `telemetry/f-entra-signin.json` (Identity: Entra ID cloud sign-ins, OWA app, MFA results)

2. **Map the eight observation statements**:
   Match each statement to its single source letter (`a` through `f`):
   1. The exact command line `whoami /all` was typed on an Accounts Payable workstation. → `d`
   2. A workstation asked DNS for `c2.stonewick[.]example` and got an answer. → `b`
   3. An SSH login to WEB01 failed for an invalid username. → `e`
   4. `m.reyes` signed in to OWA and satisfied an MFA prompt. → `f`
   5. A domain logon to DC01 failed with a bad password. → `c`
   6. A workstation held a ~40-minute encrypted TLS session; only bytes and duration are visible. → `a`
   7. `t.aoki` authenticated to DC01 over the network (logon type 3). → `c`
   8. A user logged in to WEB01 via SSH publickey. → `e`

3. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set each `q1`..`q8` field to its corresponding lowercase source letter (`a`-`f`).

4. **Check your work**:
   ```bash
   lab check soc L1.1
   ```
