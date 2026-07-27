## BRIEF
Rust enforces the fundamental **Aliasing XOR Mutation** law:
- Data may have **any number of shared references (`&T`)** OR **exactly one mutable reference (`&mut T`)**, but **never both at the same time**.
- **Non-Lexical Lifetimes (NLL)**: A reference borrow ends at its **last use**, not at the closing brace of its scope. Reordering reads before writes is often the idiomatic minimal fix.
- **Rule**: Do NOT use `.clone()` to bypass borrow errors.

In this lab, you read error `E0502` on `broken.rs`, record your answers in `answers.txt`, and apply the minimal statement-reordering fix in `fixed.rs`.

## GUIDED STEPS

1. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn main() {
       let mut queue = String::from("alert-1");
       let snapshot = &queue;
       queue.push_str(",alert-2");
       println!("snapshot = {snapshot}");
       println!("queue = {queue}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe compiler error `error[E0502]: cannot borrow queue as mutable because it is also borrowed as immutable`.

2. **Record error code and answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `error_code=E0502`
   - `q2=b` (the live `&` borrow `snapshot` overlapped the `&mut` borrow needed by `push_str`)
   - `q3=b` (under NLL, a reference borrow ends at its last use)

3. **Apply the minimal fix in `fixed.rs`**:
   Copy `broken.rs` to `fixed.rs`:
   ```bash
   cp broken.rs fixed.rs
   ```
   In `fixed.rs`, move `println!("snapshot = {snapshot}");` to directly **above** `queue.push_str(",alert-2");`:
   ```rust
   fn main() {
       let mut queue = String::from("alert-1");
       let snapshot = &queue;
       println!("snapshot = {snapshot}");
       queue.push_str(",alert-2");
       println!("queue = {queue}");
   }
   ```
   > [!WARNING]
   > Do NOT use `snapshot.clone()`. Using `.clone()` bypasses the borrow checker instead of learning reference scopes.

4. **Compile and execute `fixed.rs`**:
   ```bash
   rustc fixed.rs -o fixed && ./fixed
   ```
   Verify it outputs:
   ```text
   snapshot = alert-1
   queue = alert-1,alert-2
   ```

5. **Verify your work**:
   ```bash
   lab check rust L2.4
   ```
