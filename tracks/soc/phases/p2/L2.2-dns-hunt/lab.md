## BRIEF
DNS abuse has a *shape*: the tunnel is one host, one zone, long high-entropy labels, TXT-heavy,
NXDOMAIN-heavy, at a rate no human ever generates. Benign NXDOMAIN noise (wpad lookups, a typo'd
hostname) looks nothing like it once you count. In this lab you hunt `dns.log` for the tunnel and
prove it's not just noise.

## GUIDED STEPS

1. **Count queries per source host** — one host should dwarf the rest:
   ```bash
   awk -F'\t' '!/^#/{print $3}' dns.log | sort | uniq -c | sort -rn
   ```
   ```
       42 10.20.31.112
        6 10.20.30.107
        5 10.20.30.103
        1 10.20.10.9
        1 10.20.10.20
   ```
   `10.20.31.112` sent more than four times everyone else combined. Start there.

2. **Find the shared parent zone of that host's queries**:
   ```bash
   awk -F'\t' '!/^#/ && $3=="10.20.31.112"{print $8}' dns.log \
     | awk -F'.' '{print $(NF-2)"."$(NF-1)"."$NF}' | sort | uniq -c
   ```
   ```
        1 saas.mail.example
       40 tun.stonewick.example
        1 wpad.coppermine.example
   ```
   Forty of that host's queries share one zone: `tun.stonewick.example`. The other two are
   ordinary background traffic (webmail poll, a wpad lookup) — the same host can do both.

3. **Check the shape of the tunnel-zone traffic specifically**:
   ```bash
   awk -F'\t' '!/^#/ && $3=="10.20.31.112" && $8 ~ /tun\.stonewick\.example$/ {print $9, $10}' \
     dns.log | sort | uniq -c
   ```
   ```
        6 A NXDOMAIN
        5 TXT NOERROR
       29 TXT NXDOMAIN
   ```
   `TXT` + `NXDOMAIN` dominates (29 of 40). That's the tell: long random labels, mostly TXT, mostly
   no answer — a covert channel, not a broken app. (Broken-app NXDOMAIN storms, like the `wpad`
   noise above, come from *many* hosts with short, meaningful names — nothing like this.)

4. **Get the exact count and one event id, scoped to the tunnel zone** (not the host's total
   traffic — that host also made two ordinary queries):
   ```bash
   awk -F'\t' '!/^#/ && $3=="10.20.31.112" && $8 ~ /tun\.stonewick\.example$/' dns.log | wc -l
   awk -F'\t' '!/^#/ && $3=="10.20.31.112" && $8 ~ /tun\.stonewick\.example$/ {print $NF; exit}' \
     dns.log
   ```
   ```
   40
   CM-0312-0310
   ```

5. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: the source IP doing the tunneling, defanged (`10.20.31[.]112`)
   - `q2`: the tunnel zone, defanged (`tun.stonewick[.]example`)
   - `q3`: dominant qtype of the tunnel traffic (`txt`)
   - `q4`: dominant rcode of the tunnel traffic (`nxdomain`)
   - `q5`: count of tunnel-zone queries from that host (`40`)
   - `q6`: one event_id of a tunnel query (`cm-0312-0310`)

6. **Check your work**:
   ```bash
   lab check soc L2.2
   ```
