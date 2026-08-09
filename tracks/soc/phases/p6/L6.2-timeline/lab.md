## BRIEF
Normalize mixed timestamps (syslog local CDT + Windows/ECS UTC) to UTC and order events e1..e7 chronologically.

## GUIDED STEPS

1. Inspect `files/raw-syslog.txt`, `files/windows.json`, and `files/ecs.jsonl`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: UTC instant of WEB01 syslog line (ISO lower z, e.g. 2026-03-12t20:15:33z) -> `2026-03-12t20:15:33z`
   - `q_order`: comma-separated sequence of labels e1..e7 in UTC order -> `e4,e1,e2,e3,e5,e6,e7`
   - `q2`: Event ID of earliest attacker action -> `cm-0311-0142`
   - `q3`: Field name you must NEVER order by (arrival, not occurrence) -> `event.ingested`
   - `q4`: UTC offset of WEB01 syslog collector during CDT -> `-05:00`
4. Run `lab check soc L6.2`.
