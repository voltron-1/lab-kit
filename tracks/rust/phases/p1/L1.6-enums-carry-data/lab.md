## BRIEF
Unlike traditional C enums (which are named integer constants), Rust enums are **tagged unions**:
- Each variant can carry different typed data payloads (unit, tuple, or struct fields).
- Pattern matching (`match`) **destructures** payloads and can even filter on inner values (e.g. `success: true`).
- Invalid state combinations become unrepresentable at compile time.

In this lab, you decode data-carrying enum variants and destructuring pattern arms in `sample.rs`.

## GUIDED STEPS

1. **Read `sample.rs`**:
   Inspect `sample.rs`:
   ```rust
   enum Event {
       Login { user: String, success: bool },
       PortScan { first: u16, last: u16 },
       Heartbeat,
   }

   fn describe(event: &Event) -> String {
       match event {
           Event::Login { user, success: true } => format!("login ok: {user}"),
           Event::Login { user, success: false } => format!("login FAIL: {user}"),
           Event::PortScan { first, last } => format!("scan {first}-{last}"),
           Event::Heartbeat => String::from("heartbeat"),
       }
   }

   fn main() {
       let feed = [
           Event::Login { user: String::from("root"), success: false },
           Event::PortScan { first: 1, last: 1024 },
           Event::Heartbeat,
       ];
       for event in &feed {
           println!("{}", describe(event));
       }
   }
   ```

2. **Compile and run `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Observe the 3 printed lines.

3. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `q1=b` (Rust enums are tagged unions carrying variant-specific payloads)
   - `q2=b` (matches only `Login` events where `success` is `true`, binding `user`)
   - `q3=scan 1-1024` (exact printed line for the `PortScan` variant)

4. **Verify your work**:
   ```bash
   lab check rust L1.6
   ```
