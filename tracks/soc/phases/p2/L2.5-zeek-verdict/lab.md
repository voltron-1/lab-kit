## BRIEF
Zeek splits one conversation across multiple logs — `conn`, `dns`, `http`, `ssl` — and the `uid`
field is the key that joins them back into a single story: the same `uid` appearing in two logs
means those two rows describe the *same connection*. When a `uid` isn't shared (a DNS lookup is its
own connection, separate from the session that uses the answer), pivot on the resolved value
instead. In this lab you join four logs by `uid` and by IP to reconstruct one incident.

## GUIDED STEPS

1. **Find the uid shared between the `/u.sh` conn row and its http row**:
   ```bash
   grep -h "10.20.10.20" conn.log http.log | awk -F'\t' '{print $2}'
   ```
   ```
   CXush1
   CXush1
   ```
   Same `uid` in both logs — `conn.log` tells you *how* that connection ended (`SF`, bytes each
   way); `http.log` tells you *what* was requested. Two logs, one conversation.

2. **Find the field that carries the beacon's destination hostname**:
   The beacon's `conn.log` row (`uid CXbeac1`) only shows an IP (`203.0.113.66`). Its `ssl.log` row,
   same `uid`, has a `server_name` column — that's the SNI, the hostname.

3. **Pivot from DNS to the beacon by resolved IP** (the DNS row has its own `uid` — it doesn't share
   one with the beacon's conn row, because a lookup and the session that uses the answer are
   different connections):
   ```bash
   awk -F'\t' '!/^#/ && $5=="203.0.113.66"{print $5}' conn.log
   awk -F'\t' '!/^#/ && $11=="203.0.113.66"{print $11}' dns.log
   ```
   ```
   203.0.113.66
   203.0.113.66
   ```
   The beacon conn row's `id.resp_h` matches the dns row's `answers` value — that's the pivot: the
   lookup that resolved the name the beacon then connected to.

4. **Get the beacon's ssl-log event id**:
   ```bash
   awk -F'\t' '!/^#/{print $NF}' ssl.log
   ```
   ```
   CM-0311-0502
   ```

5. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: the uid shared by the `/u.sh` conn row and its http row (`cxush1`)
   - `q2`: the ssl.log field name that carries the C2 destination hostname (`server_name`)
   - `q3`: the dns `answers` value the beacon conn row's `id.resp_h` matches, defanged
     (`203.0.113[.]66`)
   - `q4`: which log tells you how a connection ended (`conn`)
   - `q5`: event_id of the ssl row for the beacon (`cm-0311-0502`)

6. **Check your work**:
   ```bash
   lab check soc L2.5
   ```

## SECURITY ONION (OPTIONAL)
In `cardinal-so`, these same zeek logs are the Hunt UI's correlation view; clicking a connection
pivots by uid automatically. The flat-file `grep`/`awk` path above is the graded one.
