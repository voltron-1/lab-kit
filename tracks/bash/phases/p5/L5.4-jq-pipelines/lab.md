## BRIEF
`reshape-ecs.sh` reads raw JSON log lines and reshapes each one into
ECS-style dotted fields (`source.ip`, `user.name`, …) — exactly the kind
of filter that turns an app's native log format into what a SIEM expects.
Real, correct, safe to run for real. Your job is DECODE: name what each
part of the filter does.

## GUIDED STEPS

1. Look at the raw input first:

       cat events.jsonl

   ```json
   {"ts":"2026-07-18T10:00:00Z","src_ip":"203.0.113.7","user":"alice","action":"login_failed"}
   {"ts":"2026-07-18T10:00:05Z","src_ip":"203.0.113.7","user":"alice","action":"login_failed"}
   {"ts":"2026-07-18T10:00:10Z","src_ip":"198.51.100.23","user":"bob","action":"login_success"}
   ```

   Three flat JSON objects, one per line (NDJSON) — plain field names,
   nothing ECS-shaped yet.

2. Read the filter:

       cat reshape-ecs.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — read, decode, and run for real.
   set -euo pipefail
   jq -c '{
     "@timestamp":    .ts,
     "source.ip":     .src_ip,
     "user.name":     .user,
     "event.action":  .action,
     "event.outcome": (if (.action | test("failed")) then "failure" else "success" end)
   }' events.jsonl
   ```

   `-c` prints each result **compact** — one JSON object per line, not
   pretty-printed across many. Every key in the `{ }` object-construction
   block is a **literal** string — `"source.ip"` is one key with a dot in
   its name, not shorthand for a nested `.source.ip` path; that's exactly
   how a flat schema like ECS represents what looks like nesting. Four of
   the five fields are straight renames (`.ts` → `@timestamp`, `.src_ip`
   → `source.ip`, …). `event.outcome` (line 9) is different: it's
   **derived** — not copied from the input at all, but computed by an
   inline `if (.action | test("failed")) then "failure" else "success"
   end`, where `test("failed")` runs a **regex** match of the pattern
   `"failed"` against whatever `.action` piped in.

3. Run it for real:

       ./reshape-ecs.sh

   captured output:

       ```
       {"@timestamp":"2026-07-18T10:00:00Z","source.ip":"203.0.113.7","user.name":"alice","event.action":"login_failed","event.outcome":"failure"}
       {"@timestamp":"2026-07-18T10:00:05Z","source.ip":"203.0.113.7","user.name":"alice","event.action":"login_failed","event.outcome":"failure"}
       {"@timestamp":"2026-07-18T10:00:10Z","source.ip":"198.51.100.23","user.name":"bob","event.action":"login_success","event.outcome":"success"}
       ```

   Both of alice's `login_failed` events got `event.outcome":"failure"`;
   bob's `login_success` got `"success"` — the derived field tracks
   `.action`, not a copy of anything in the input.

4. Confirm ShellCheck's take:

       shellcheck reshape-ecs.sh

   captured output: *(nothing — clean, no warnings)*

5. Answer the comprehension check. Write `answers.txt`:

       flag_c=compact
       key_style=literal
       line9=derived
       test_fn=regex

6. `lab check bash L5.4`
