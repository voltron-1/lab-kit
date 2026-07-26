## BRIEF
Function signatures in Rust communicate ownership semantics directly:
- A parameter typed `&str` **borrows** data temporarily; the caller retains ownership.
- A parameter typed `String` (without `&`) **takes ownership**; the caller's value is moved and can no longer be used.

In this lab, you decode function signatures in `sample.rs` and inspect compiler error `E0382` (use of moved value).

## GUIDED STEPS

1. **Read `sample.rs`**:
   Inspect `sample.rs`:
   ```rust
   fn shout(message: &str) -> String {
       message.to_uppercase()
   }

   fn consume(message: String) -> usize {
       message.len()
   }

   fn main() {
       let alert = String::from("port scan detected");
       let loud = shout(&alert);
       println!("{loud}");

       let size = consume(alert);
       println!("{size} bytes");

       // step 4: uncomment the next line, recompile, read the error, re-comment it
       // println!("{alert}");
   }
   ```

2. **Record initial answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `q1=b` (`alert` remains usable after `shout(&alert)` because `&str` borrows)
   - `q2=b` (`consume(alert)` takes ownership, moving `alert`)

3. **Compile and execute `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Verify it prints `PORT SCAN DETECTED` and `18 bytes`.

4. **Experiment with use-after-move**:
   Uncomment line 15 (`// println!("{alert}");`) in `sample.rs`.
   Compile:
   ```bash
   rustc sample.rs
   ```
   Observe the compiler error `error[E0382]: borrow of moved value: alert`.
   In `answers.txt`, set `q3=E0382`.

5. **Re-comment line 15 and recompile**:
   Re-comment `// println!("{alert}");` in `sample.rs` and recompile so `./sample` builds cleanly:
   ```bash
   rustc sample.rs -o sample
   ```

6. **Verify your work**:
   ```bash
   lab check rust L1.4
   ```
