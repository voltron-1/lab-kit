## BRIEF
In Rust, almost everything is an **expression** that returns a value:
- **Block expressions** `{ ... }`: Evaluate to their final expression when omitted of a trailing semicolon. Adding a semicolon converts the value to `()`.
- **Function bodies**: The last expression without a semicolon is the implicit return value.
- **`if` expressions**: Both `if` and `else` branches return values, and **both arms must produce the exact same type**.

In this lab, you predict block and `if` expression values in `sample.rs` and observe compiler error `E0308` in `broken.rs`.

## GUIDED STEPS

1. **Read `sample.rs` and predict outputs**:
   Inspect `sample.rs`:
   ```rust
   fn classify(port: u32) -> &'static str {
       if port < 1024 { "well-known" } else { "registered" }
   }

   fn main() {
       let x = {
           let a = 3;
           a * a
       };
       println!("x = {x}");

       let kind = classify(443);
       println!("kind = {kind}");

       let parity = if x % 2 == 0 { "even" } else { "odd" };
       println!("parity = {parity}");
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `x=9` (block evaluates `3 * 3`)
   - `kind=well-known` (`443 < 1024`)
   - `parity=odd` (`9 % 2 != 0`)

3. **Compile and run `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Confirm the outputs match your predictions.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn main() {
       let width = if true { 5 } else { "six" };
       println!("width = {width}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe the compiler error tag `error[E0308]: `if` and `else` have incompatible types`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0308`.

6. **Verify your work**:
   ```bash
   lab check rust L1.3
   ```
