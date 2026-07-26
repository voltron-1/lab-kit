## BRIEF
Shared references (`&T`) allow non-owning access to data:
- Any number of `&T` references may exist simultaneously.
- All shared references are **read-only**: you cannot mutate data through a `&T` reference.
- Passing a `&T` reference to a function leaves the owner with full ownership.
- Attempting to mutate data through a shared reference produces error `E0596`.

In this lab, you predict shared borrowing semantics in `sample.rs` and inspect `E0596` in `broken.rs`.

## GUIDED STEPS

1. **Read `sample.rs` and predict outputs**:
   Inspect `sample.rs`:
   ```rust
   fn longest_len(a: &String, b: &String) -> usize {
       if a.len() > b.len() { a.len() } else { b.len() }
   }

   fn main() {
       let host = String::from("bastion-01");
       let alias = &host;
       let alias2 = &host;
       println!("{alias} / {alias2} / {host}");

       let primary = String::from("core-router");
       let backup = String::from("edge-fw");
       let max = longest_len(&primary, &backup);
       println!("max = {max}");
       println!("{primary} + {backup} still here");
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `alias=bastion-01` (`alias` is a shared reference `&host`)
   - `max=11` (`"core-router"` has length 11, `"edge-fw"` has length 7)

3. **Compile and execute `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Verify outputs match your predictions.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   fn main() {
       let config = String::from("mode=passive");
       let view = &config;
       view.push_str(";debug=1");
       println!("{view}");
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe compiler error `error[E0596]: cannot borrow *view as mutable, as it is behind a & reference`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0596`.

6. **Verify your work**:
   ```bash
   lab check rust L2.3
   ```
