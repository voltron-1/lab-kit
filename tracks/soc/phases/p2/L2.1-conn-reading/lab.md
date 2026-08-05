## BRIEF
A zeek `conn.log` row is a sentence about one conversation: *who* talked to *whom*, on *what*
port/service, for *how long*, *how many bytes* each way, and *how it ended*. In this lab you read
nine `conn.log` rows from a Coppermine workstation's traffic and pick the odd conversation out.

## GUIDED STEPS

1. **Read the header, then line the rows up**:
   ```bash
   head -7 conn.log
   column -t conn.log
   ```
   The `#fields` line names every column in order: `ts uid id.orig_h id.orig_p id.resp_h id.resp_p
   proto service duration orig_bytes resp_bytes conn_state history event_id`. `id.orig_*` is always
   the host that **opened** the connection; `orig_bytes`/`resp_bytes` count from that same point of
   view. `conn-state-legend.md` decodes the `conn_state` column (`SF`, `S0`, `REJ`, `RSTO`, ...).

2. **Find the rejected scanner connection**:
   ```bash
   awk -F'\t' '$12=="REJ"{print}' conn.log
   ```
   ```
   2026-03-11T15:10:00Z	CRD00006	192.0.2.199	51000	10.20.10.20	22	tcp	-	0.00	0	0	REJ	Sr	CM-0311-0514
   ```
   `192.0.2.199` (a research scanner) tried port 22 on WEB01 and got rejected outright — `0`
   bytes either way, `conn_state REJ`. Its `uid` is `CRD00006`.

3. **Count the `S0` (no-reply) rows**:
   ```bash
   awk -F'\t' '$12=="S0"{c++} END{print c}' conn.log
   ```
   ```
   2
   ```
   Two rows show a query sent with no reply ever seen — the NTP hit from WKS-HD-03 and a DNS query
   from WKS-ENG-12. `S0` is not necessarily hostile; it just means nobody answered.

4. **Spot the odd conversation out**:
   Two rows go to `203.0.113.66:443` over `ssl` from the same workstation, five minutes apart: `0.31s`
   / `517B<->1203B` and `0.29s` / `511B<->1198B`. Compare that to the *other* 443/tcp/ssl row — a `42.3s`
   session moving `4201B<->8830B` to `192.0.2.60` (the saas webmail host). Short, tiny, and repeating on
   an external IP that isn't webmail is the tell: this is automation, not a person browsing.

5. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: uid of the rejected scanner row (`crd00006`)
   - `q2`: conn_state of the 445/tcp svc_backup copy (`sf`)
   - `q3`: service label of the short external 443 conversation (`ssl`)
   - `q4`: resp_bytes of that beacon's first hit (`1203`)
   - `q5`: the external dst IP a workstation opened 443 to, that isn't saas webmail — defanged
     (`203.0.113[.]66`)
   - `q6`: how many rows show `conn_state S0` (`2`)

6. **Check your work**:
   ```bash
   lab check soc L2.1
   ```
