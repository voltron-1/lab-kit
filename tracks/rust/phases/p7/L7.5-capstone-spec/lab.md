## BRIEF
Write the specification for the course capstone: an IOC log parser emitting Elastic Common Schema (ECS) JSON.

## GUIDED STEPS

1. Inspect `files/sample.log` and `files/ecs-fields.md`.
2. Determine essential constraints (a, b, d, f, g).
3. Create `answers.txt`:
   ```text
   essential=a,b,d,f,g
   ```
4. Create `spec.md` naming `@timestamp`, `event.outcome`, no-panic on malformed lines, and JSON serialization using serde_json.
5. Verify with `lab check rust L7.5`.
