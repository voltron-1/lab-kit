## BRIEF
Rust distinguishes implicit bitwise copying from explicit heap cloning:
- **`Copy` types**: Primitive numbers (`u16`, `i32`), booleans, and small structs deriving `#[derive(Clone, Copy)]` whose fields are all `Copy`. Assignment duplicates bits without invalidating the original.
- **Heap-owning types**: Types like `String` or `Vec` own external resources. They can NEVER implement `Copy`. Explicit duplication requires `.clone()`.
- Deriving `Copy` on a type containing non-`Copy` fields causes compiler error `E0204`.

In this lab, you predict `Copy` vs `Clone` behaviors in `sample.rs` and inspect `E0204` in `broken.rs`.

## GUIDED STEPS

1. **Read `sample.rs` and predict outputs**:
   Inspect `sample.rs`:
   ```rust
   #[derive(Clone, Copy)]
   struct PortRange {
       first: u16,
       last: u16,
   }

   fn width(range: PortRange) -> u16 {
       range.last - range.first
   }

   fn main() {
       let a = 41;
       let b = a;
       println!("a = {a}, b = {b}");

       let scan = PortRange { first: 20, last: 25 };
       let w = width(scan);
       println!("w = {w}");
       println!("scan.first = {}", scan.first);

       let name = String::from("dmz-probe");
       let copy_of_name = name.clone();
       println!("{name} / {copy_of_name}");
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `b=41` (`a` is an integer; assignment copies bits, leaving `a` active)
   - `w=5` (`25 - 20 = 5`)
   - `first=20` (`PortRange` derives `Copy`, so `scan` is copied into `width(scan)` and remains usable)

3. **Compile and execute `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Verify outputs match your predictions.

4. **Attempt compiling `broken.rs`**:
   Inspect `broken.rs`:
   ```rust
   #[derive(Clone, Copy)]
   struct Session {
       id: u32,
       token: String,
   }

   fn main() {
       let s = Session { id: 7, token: String::from("abc") };
       println!("{} {}", s.id, s.token);
   }
   ```
   Compile `broken.rs`:
   ```bash
   rustc broken.rs
   ```
   Observe compiler error `error[E0204]: the trait Copy cannot be implemented for this type`.

5. **Record the compiler error code**:
   In `predictions.txt`, set `error=E0204`.

6. **Verify your work**:
   ```bash
   lab check rust L2.2
   ```
