## BRIEF
HTTP exposes the request: method, host, uri, user-agent, status code — all in the clear. HTTPS
hides the uri and body, but the SNI (`server_name` in zeek's `ssl.log`) is the destination hostname
you still get — until a resumed session drops it. In this lab you read both logs and learn which
fields survive encryption and which don't.

## GUIDED STEPS

1. **Find the status code of the plaintext payload pull**:
   ```bash
   awk -F'\t' '!/^#/ && $9=="/u.sh"{print $11}' http.log
   ```
   ```
   200
   ```
   `/u.sh` is fetched over plaintext HTTP (port 80), so the full request line — method, host, uri,
   user-agent — is readable in `http.log`.

2. **Find the C2's SNI in the first TLS handshake**:
   ```bash
   awk -F'\t' '!/^#/ && $5=="203.0.113.66" && $9!="-"{print $9; exit}' ssl.log
   ```
   ```
   c2.stonewick.example
   ```
   The C2 session is TLS-only — `http.log` has no row for it at all. `ssl.log`'s `server_name`
   (the SNI from the ClientHello) is the only destination hostname you get.

3. **Spot the user-agent that isn't a browser**:
   ```bash
   awk -F'\t' '!/^#/{print $10}' http.log | grep -i windowspowershell
   ```
   ```
   Mozilla/5.0 (WindowsPowerShell/5.1)
   ```
   Real browsers announce themselves with predictable UA strings. A UA naming a scripting engine on
   an *outbound* request — `curl`, `WindowsPowerShell` — is a cheap, useful tell, independent of
   whether the traffic is otherwise unremarkable (this one is a `200 OK`, no obvious red flag except
   the UA itself).

4. **Check what that same host sent** (method matters — POSTing data out is different from fetching
   a page):
   ```bash
   awk -F'\t' '!/^#/ && $9=="/telemetry"{print $7}' http.log
   ```
   ```
   POST
   ```

5. **Compare the beacon's first TLS row to a later, resumed one**:
   ```bash
   awk -F'\t' '!/^#/ && $10=="T"{print $9}' ssl.log
   ```
   ```
   -
   ```
   Real TLS session resumption skips the full handshake, and `server_name` is only set during a full
   ClientHello — a resumed row can show `-` even for the exact same destination. If you only look at
   a resumed row, you lose the SNI; the first handshake is where it lives.

6. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: status code of the `/u.sh` payload pull (`200`)
   - `q2`: SNI of the beacon's first TLS handshake, defanged (`c2.stonewick[.]example`)
   - `q3`: the scripting-engine user-agent, verbatim lowercased (`mozilla/5.0 (windowspowershell/5.1)`)
   - `q4`: HTTP method that sent data to the server (`post`)
   - `q5`: `server_name` of the resumed TLS row (`-`)
   - `q6`: which log carries an HTTPS session's destination hostname (`ssl`)

7. **Check your work**:
   ```bash
   lab check soc L2.3
   ```
