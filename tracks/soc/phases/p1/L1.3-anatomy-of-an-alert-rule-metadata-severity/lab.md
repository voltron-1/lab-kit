## BRIEF
A SIEM alert is a structured claim about underlying evidence.
Rule metadata (`rule.id`, `rule.severity`) specifies the detection logic pattern, while `evidence.event_ids` cites the specific raw log events that triggered the rule.
However, detection rules are narrow: an alert cites only the events that matched its trigger condition, not the complete incident. In this lab, you inspect SIEM alert `alert-CM-A-1024.json`, examine its cited evidence events, and pivot into `events/raw.jsonl` to discover critical uncited context.

## GUIDED STEPS

1. **Inspect the SIEM alert (`alert-CM-A-1024.json`)**:
   Examine the alert's rule metadata, severity, risk score, and evidence citations using `jq`:
   ```bash
   jq . alert-CM-A-1024.json
   jq -r '.rule.id' alert-CM-A-1024.json
   jq -r '.evidence.event_ids[]' alert-CM-A-1024.json
   ```

2. **Examine the cited evidence events in `events/raw.jsonl`**:
   Filter `events/raw.jsonl` for the three event IDs cited in `evidence.event_ids`:
   ```bash
   grep -E 'CM-0311-0107|CM-0311-0121|CM-0311-0135' events/raw.jsonl | jq -c '{id: .["event.id"], code: .["event.code"], user: .["user.name"], ip: .["source.ip"]}'
   ```
   Notice that while the username (`user.name`) varies across each cited failed logon event, the originating IP address (`source.ip`) remains constant (`203.0.113.66`).

3. **Pivot into `events/raw.jsonl` to find uncited activity**:
   Search `events/raw.jsonl` for any successful logon events (Event ID `4624`):
   ```bash
   grep '"event.code": "4624"' events/raw.jsonl | jq .
   ```
   Notice event `CM-0311-0142`: a successful network logon (`4624` type 3) for `m.reyes` from `203.0.113.66` at 14:22:31Z.
   The password spray detection rule only monitored `4625` failures, leaving this successful authentication uncited — transforming the triage story from "attempted spray" to "compromised credential"!

4. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: Rule ID of the alert (`cm-r-0117`)
   - `q2`: Dotted JSON path of the static rule severity field (`rule.severity`)
   - `q3`: The 3 cited event IDs in array order (`cm-0311-0107,cm-0311-0121,cm-0311-0135`)
   - `q4`: Originating IP entity value unchanged across cited events (`203.0.113.66`)
   - `q5`: Event ID of the uncited logon success (`cm-0311-0142`)

5. **Check your work**:
   ```bash
   lab check soc L1.3
   ```
