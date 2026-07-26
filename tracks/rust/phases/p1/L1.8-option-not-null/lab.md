## BRIEF
Rust eliminates `NULL` pointer exceptions by replacing null with the `Option<T>` enum:
- `Option<T>` variants: `Some(T)` (contains a value) or `None` (represents absence).
- The type system **quarantines** optional values: an `Option<u16>` is NOT a `u16`, preventing accidental un-checked access.
- Safe extraction methods: `unwrap_or(default)`, `if let Some(val) = ...`, or `match`.

In this lab, you predict `Option<T>` behaviors in `sample.rs` and observe type error `E0308` in `broken.rs`.

## GUIDED STEPS

1. **Read `sample.rs` and predict outputs**:
   Inspect `sample.rs`:
   ```rust
   fn find_port(service: &str) -> Option<u16> {
       match service {
           "ssh" => Some(22),
           "https" => Some(443),
           "dns" => Some(53),
           _ => None,
       }
   }

   fn main() {
       println!("{:?}", find_port("ssh"));
       println!("{:?}", find_port("gopher"));

       let fallback = find_port("telnet").unwrap_or(0);
       println!("fallback = {fallback}");

       if let Some(port) = find_port("dns") {
           println!("dns runs on {port}");
       }
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `p1=Some(22)` (`find_port("ssh")` returns `Some(22)`)
   - `p2=None` (`find_port("gopher")` returns `None`)
   - `p3=0` (`telnet` is missing, `unwrap_or(0)` yields fallback `0`)
   - `p4=53` (`find_port("dns")` matches `Some(53)`, `port` binds `53`)

3. **Compile and run `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Verify outputs match your predictions.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn find_port(service: &str) -> Option<u16> {
       match service {
           "ssh" => Some(22),
           _ => None,
       }
   }

   fn main() {
       let port: u16 = find_port("ssh");
       println!("port = {port}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe `error[E0308]: mismatched types: expected u16, found Option<u16>`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0308`.

6. **Verify your work**:
   ```bash
   lab check rust L1.8
   ```
