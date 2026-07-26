## BRIEF
In Rust, assigning a non-`Copy` value (like `String`) or passing it by value to a function **moves** ownership:
- The original variable becomes **dead at compile time**; attempting to use it causes error `E0382`.
- A move transfers pointer ownership without copying heap buffer bytes.
- Explicit duplication requires `.clone()`.

In this lab, you predict move semantics in `sample.rs` and inspect compiler error `E0382` in `broken.rs`.

## GUIDED STEPS

1. **Read `sample.rs` and predict outputs**:
   Inspect `sample.rs`:
   ```rust
   fn register(tag: String) -> usize {
       tag.len()
   }

   fn main() {
       let alpha = String::from("intrusion");
       let beta = alpha;
       println!("beta = {beta}");

       let gamma = String::from("port-22");
       let size = register(gamma);
       println!("size = {size}");

       let delta = beta.clone();
       println!("delta = {delta}");
       println!("beta again = {beta}");
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `beta=intrusion` (`alpha` moved into `beta`)
   - `size=7` (`gamma` moved into `register`, length of `"port-22"` is `7`)
   - `delta=intrusion` (`beta` explicitly cloned into `delta`)

3. **Compile and execute `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Verify outputs match your predictions.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn main() {
       let session = String::from("sess-491");
       let backup = session;
       println!("backup = {backup}");
       println!("session = {session}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe compiler error `error[E0382]: borrow of moved value: session`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0382`.

6. **Verify your work**:
   ```bash
   lab check rust L2.1
   ```
