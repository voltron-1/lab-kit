# L2.7 — Lifetimes — reading 'a without fear

## BRIEF
- Read `'a` as a validity region: lifetime parameters state compile-time relationships between borrowed references.
- Understand function lifetime signatures: `longer<'a>(a: &'a str, b: &'a str) -> &'a str` promises the returned reference lives only as long as both inputs.
- Understand struct lifetime annotations: `struct Finding<'a>` implies an instance cannot outlive the string data it borrows.
- Perform a guided experiment causing compiler error `E0597` (`secondary` does not live long enough), then revert and run `sample.rs`.

## GUIDED STEPS

### 1. Inspect `sample.rs`
Read `sample.rs`:
```rust
fn longer<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

struct Finding<'a> {
    rule: &'a str,
}
```
Key observations:
- `'a` names a **validity region** enforced at compile time and erased at runtime.
- `longer` requires explicit `'a` annotations because it accepts two input references and returns one output reference.
- `winner` is evaluated inside an inner scope where `secondary` is alive.

### 2. Perform the `E0597` Guided Experiment
To observe how lifetime constraints are enforced:
1. Temporarily move `println!("winner = {winner}");` OUTSIDE (below) the inner `{ ... }` block.
2. Run `rustc sample.rs`.
3. Note the compiler error tag `error[E0597]: \`secondary\` does not live long enough`.
4. Record `E0597` as your answer for `q5` in `answers.txt`.
5. Move `println!("winner = {winner}");` back inside the inner scope so `sample.rs` compiles again.

### 3. Record Graded Answers in `answers.txt`
In `answers.txt`, set keys `q1` through `q5`:

- `q1`: What does `'a` in `longer<'a>(a: &'a str, b: &'a str) -> &'a str` promise?
  - `a`: The output string is heap-allocated
  - `b`: The returned reference is valid only while both inputs are — the shorter-lived input bounds it
  - `c`: Inputs must be `'static` literals
- `q2`: What string value is printed for `winner`?
- `q3`: What does `struct Finding<'a>` tell a code reader?
  - `a`: `Finding` owns its rule string
  - `b`: `Finding` borrows — an instance cannot outlive the string it points into
  - `c`: `rule` is an optional field
- `q4`: What are lifetime parameters at runtime?
  - `a`: Garbage-collector metadata
  - `b`: Nothing — compile-time proof, erased from the compiled binary
  - `c`: Debug-build assertion checks
- `q5`: The error code observed in step 2 (e.g. `E0597`)

### 4. Compile and Run `sample.rs`
Compile and execute `sample.rs`:
```bash
rustc sample.rs -o sample && ./sample
```

### Graded Answer Format (`answers.txt`)
```txt
q1=b
q2=credential-stuffing
q3=b
q4=b
q5=E0597
```
