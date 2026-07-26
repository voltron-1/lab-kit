## BRIEF
Pattern matching in Rust requires **exhaustiveness**: the compiler proves at compile time that every possible enum variant is handled.
- Missing a variant triggers compiler error `E0004`.
- **Security Rule**: Fix non-exhaustive matches by explicitly naming the missing variant (`Severity::Critical => "isolate host"`), **never by adding a wildcard (`_ => ...`)**. Wildcards silently absorb new variants added in future code changes without review.

In this lab, you read `E0004` on `broken.rs`, copy to `fixed.rs`, and implement the explicit missing arm.

## GUIDED STEPS

1. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   enum Severity {
       Low,
       Medium,
       High,
       Critical,
   }

   fn action(level: Severity) -> &'static str {
       match level {
           Severity::Low => "log only",
           Severity::Medium => "open ticket",
           Severity::High => "page on-call",
       }
   }

   fn main() {
       let alerts = [
           Severity::Low,
           Severity::Medium,
           Severity::High,
           Severity::Critical,
       ];
       for level in alerts {
           println!("{}", action(level));
       }
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe `error[E0004]: non-exhaustive patterns: Severity::Critical not covered`.

2. **Record the compiler error code**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set `error_code=E0004`.

3. **Apply the explicit fix in `fixed.rs`**:
   Copy `broken.rs` to `fixed.rs`:
   ```bash
   cp broken.rs fixed.rs
   ```
   In `fixed.rs`, add the missing arm directly to the `match` expression:
   ```rust
   Severity::Critical => "isolate host",
   ```
   > [!WARNING]
   > Do NOT use `_ => "isolate host"`. Using a wildcard bypasses exhaustiveness checks for future variants.

4. **Compile and execute `fixed.rs`**:
   ```bash
   rustc fixed.rs -o fixed && ./fixed
   ```
   Verify it prints:
   ```text
   log only
   open ticket
   page on-call
   isolate host
   ```

5. **Verify your work**:
   ```bash
   lab check rust L1.7
   ```
