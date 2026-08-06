## BRIEF
Beaconing is automation's fingerprint: a program calling home on a near-fixed interval, with small
jitter to avoid looking *too* perfectly regular. But periodic isn't automatically hostile — NTP,
mail sync, and app polls are periodic too. In this lab you find the beacon by computing deltas
yourself, then separate it from a benign periodic signal by destination, port, and byte pattern.

## GUIDED STEPS

1. **Count connections per destination — look for one that repeats a lot**:
   ```bash
   awk -F'\t' '!/^#/{print $5}' conn.log | sort | uniq -c | sort -rn
   ```
   ```
       20 192.0.2.10
       18 203.0.113.66
        6 192.0.2.60
        2 192.0.2.61
        2 10.20.10.5
        1 10.20.10.8
        1 10.20.10.20
   ```
   Two destinations dominate: `192.0.2.10` (20 hits) and `203.0.113.66` (18 hits). Both are
   candidates — the count alone doesn't tell you which is hostile.

2. **Compute the deltas for the external destination**:
   ```bash
   awk -F'\t' '!/^#/ && $5=="203.0.113.66"{print $1}' conn.log | sort | python3 -c "
   import sys
   from datetime import datetime
   lines = [datetime.fromisoformat(l.strip().replace('Z','+00:00')) for l in sys.stdin]
   for i in range(1, len(lines)):
       print((lines[i]-lines[i-1]).total_seconds())
   "
   ```
   ```
   288.0
   318.0
   275.0
   309.0
   270.0
   ...
   ```
   Every delta clusters around 300 seconds, give or take about 10% — that's jitter, not noise.

3. **Find the beaconing host**:
   ```bash
   awk -F'\t' '!/^#/ && $5=="203.0.113.66"{print $3}' conn.log | sort -u
   ```
   ```
   10.20.30.107
   ```

4. **Check the NTP destination's deltas the same way** — a sample:
   ```bash
   awk -F'\t' '!/^#/ && $5=="192.0.2.10"{print $1}' conn.log | sort | head -5
   ```
   ```
   2026-03-11T15:46:10Z
   2026-03-11T15:47:14Z
   2026-03-11T15:48:18Z
   2026-03-11T15:49:22Z
   2026-03-11T15:50:26Z
   ```
   Exactly 64 seconds apart, every time — also periodic, but `192.0.2.10:123/udp` is NTP, a known
   background service every host talks to. See `beacon-method.md` for the full delta method and why
   port/service and byte pattern (not periodicity alone) decide the verdict.

5. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: the beaconing host, defanged (`10.20.30[.]107`)
   - `q2`: the hostile beacon's destination IP, defanged (`203.0.113[.]66`)
   - `q3`: approximate base period of the hostile beacon, seconds (`300`)
   - `q4`: number of hostile beacon connections in the log (`18`)
   - `q5`: the destination that's also periodic but benign, defanged (`192.0.2[.]10`)
   - `q6`: one word for why q5 is benign despite being periodic (`ntp`)

6. **Check your work**:
   ```bash
   lab check soc L2.6
   ```
