## BRIEF
Security logs describe the same moment in multiple formats: local wall-clock syslog text, Windows EVTX XML/JSON SystemTime, and normalized Elastic Common Schema (ECS).
Naively sorting logs by raw text lines or file ingest order causes critical errors. In this lab, you compare five events (`e1` through `e5`) across three formats (`raw-syslog.txt`, `windows-raw.json`, and `ecs.jsonl`), convert Chicago local time (CDT, UTC-05:00) to UTC, and reconstruct the true chronological order.

## GUIDED STEPS

1. **Compare a single event across all three formats**:
   Search for user `j.walsh` in `raw-syslog.txt`, `windows-raw.json`, and `ecs.jsonl`:
   ```bash
   grep j.walsh raw-syslog.txt
   jq '.[] | select(.Event.EventData.TargetUserName=="j.walsh")' windows-raw.json
   grep j.walsh ecs.jsonl | jq .
   ```
   Notice how `raw-syslog.txt` records `09:00:33` (CDT local time with no year or timezone offset), `windows-raw.json` records `2026-03-10T14:00:33.412Z` (true UTC), and `ecs.jsonl` normalizes `@timestamp` to `2026-03-10T14:00:33Z`.

2. **Convert local syslog time to UTC**:
   The Duluth log collector recorded syslog lines in America/Chicago local time (CDT, UTC offset `-05:00`). To convert local time to UTC, add 5 hours (`+05:00`).
   For example, line 1 (`Mar 10 08:59:57`) corresponds to `2026-03-10T13:59:57Z`.

3. **Reconstruct true chronological order**:
   `ecs.jsonl` stores records in file ingest order (`e1`, `e2`, `e3`, `e4`, `e5`).
   Extract `@timestamp` and `labels.exercise_id` using `jq` and sort by true timestamp:
   ```bash
   jq -r '[.labels.exercise_id, ."@timestamp"] | @tsv' ecs.jsonl | sort -k2
   ```
   Observe how `e2` (`13:59:57Z`) occurred before `e1` (`14:00:33Z`), and `e4` (`14:01:05Z`) occurred before `e3` (`14:01:48Z`).

4. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: UTC ISO-8601 timestamp of the `sshd` "Accepted publickey" line (`2026-03-10t13:59:57z`)
   - `q2`: True chronological sequence of exercise labels (`e2,e1,e4,e3,e5`)
   - `q3`: ECS field name for client/source IP (`source.ip`)
   - `q4`: ECS field name for Windows event code (`event.code`)
   - `q5`: UTC offset of the syslog collector (`-05:00`)

5. **Check your work**:
   ```bash
   lab check soc L1.2
   ```
