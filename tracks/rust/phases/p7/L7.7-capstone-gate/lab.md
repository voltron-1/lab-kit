## BRIEF
This is the **Capston Gate** and the final lab of the Rust Literacy Lab course!

You perform a final audit on the finished ECS parser and ship it.

## GUIDED STEPS

1. Inspect `files/ecs_parser/src/main.rs`.
2. Create `answers.txt`:
   ```text
   a1=b
   a2=b
   a3=b
   a4=b
   a5=b
   a6=3
   ```
3. Run the parser against `files/sample.log` in your shell (or create `ecs_out.txt`):
   ```text
   {"@timestamp":"2026-07-20T10:15:00Z","event.action":"login-attempt","event.dataset":"sshd","event.outcome":"failure","message":"2026-07-20T10:15:00Z sshd FAILED user=root src=203.0.113.9","source.ip":"203.0.113.9","user.name":"root"}
   {"@timestamp":"2026-07-20T10:15:04Z","event.action":"login-attempt","event.dataset":"sshd","event.outcome":"success","message":"2026-07-20T10:15:04Z sshd OK user=deploy src=198.51.100.7","source.ip":"198.51.100.7","user.name":"deploy"}
   {"@timestamp":"2026-07-20T10:15:09Z","event.action":"login-attempt","event.dataset":"sudo","event.outcome":"failure","message":"2026-07-20T10:15:09Z sudo FAILED user=www-data src=203.0.113.9","source.ip":"203.0.113.9","user.name":"www-data"}
   ```
4. Verify with `lab check rust L7.7`.
