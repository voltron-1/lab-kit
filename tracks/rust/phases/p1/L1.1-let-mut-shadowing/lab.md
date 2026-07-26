## BRIEF
In Rust, variables are **immutable by default**. You must explicitly opt into mutability using the `mut` keyword.
Shadowing allows you to re-declare a variable with `let`, creating a new binding that can even change type (e.g., from `&str` to `usize`).

In this lab, you predict the output of `sample.rs` and inspect your first compiler rejection in `broken.rs` (`E0384`).

> [!NOTE]
> The automated check cannot verify whether you predicted before running. Honor the workflow to build strong code-reading habits!

## GUIDED STEPS

1. **Read `sample.rs` and predict the outputs**:
   Inspect `sample.rs`:
   ```rust
   fn main() {
       let x = 5;
       let x = x + 1;
       let x = x * 2;
       println!("x = {x}");

       let mut count = 10;
       count += 5;
       println!("count = {count}");

       let label = "TCP";
       let label = label.len();
       println!("label = {label}");
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Fill in your predicted values for `x` (`12`), `count` (`15`), and `label` (`3`).

3. **Compile and execute `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Compare the program's output with your predictions in `predictions.txt`.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn main() {
       let retries = 3;
       retries = 5;
       println!("retries = {retries}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe the compiler error tag `error[E0384]: cannot assign twice to immutable variable`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0384`.

6. **Verify your work**:
   ```bash
   lab check rust L1.1
   ```
