# Evidence Pack Documentation

## Pack Layout
Every SOC lab stages evidence files and an `answers.template.txt` template under `files/`.
When you run `lab start`, the CLI copies `files/` into `workspace/soc/<lab-id>` — for this lab, the destination directory is `workspace/soc/l0.2`.

## ECS Naming & Schema
All JSON log telemetry follows Elastic Common Schema (ECS) field names:
- `@timestamp`: ISO-8601 UTC timestamp (`2026-03-11T14:07:12Z`)
- `host.name`: Hostname (`DC01`, `WKS-ACCT-07`)
- `source.ip`: Originating IP address (`203.0.113.66`)
- `user.name`: Account username (`m.reyes`, `svc_backup`)
- `event.code`: Windows Event ID (`4624`, `4625`, `4688`)
- `event.id`: Unique event identifier (`CM-0311-0107`)

## Event & Alert Naming Conventions
- Events use format `CM-<MMDD>-<seq>` (e.g. `CM-0311-0107`)
- SIEM Alerts use format `CM-A-<n>` (e.g. `CM-A-0001`)
- Detection Rules use format `CM-R-<n>` (e.g. `CM-R-0112`)

## Alert JSON Structure
SIEM alerts contain rule metadata, entities, and evidence citations:
```json
{
  "alert": { "id": "CM-A-0001" },
  "@timestamp": "2026-03-11T14:07:55Z",
  "rule": { "id": "CM-R-0112", "name": "Multiple failed logons - single source" },
  "entities": { "source.ip": "203.0.113.66" },
  "evidence": { "event_ids": ["CM-0311-0107", "CM-0311-0111"] }
}
```
The `evidence.event_ids` array bridges the high-level alert to the raw events in `events.jsonl`.

## Defang Discipline
- **Raw evidence files**: NEVER defanged. They reflect realistic network and host telemetry (e.g., `c2.stonewick.example`).
- **Your prose/notes/answers**: ALWAYS defanged. Bracket the final dot (`evil[.]example`) and prepend `hxxp://` to URLs.

## Answers Convention
Copy `answers.template.txt` to `answers.txt`.
Write one `qN=value` per line using single lowercase tokens.
