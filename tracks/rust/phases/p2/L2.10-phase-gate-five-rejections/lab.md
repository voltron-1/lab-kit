# L2.10 — Phase gate: explain 5 rejected programs

## BRIEF
- Capstone Gate for Phase 2: analyze five rejected Rust programs representing the 5 core ownership/borrowing rule violations.
- Predict each compiler error code and violated rule letter from source inspection alone.
- Self-check by running `rustc rejectN.rs` for each program.
- Apply a minimal fix to `reject5.rs` by saving it as `fixed5.rs` and compiling `./fixed5`.

## GUIDED STEPS

### 1. Analyze the 5 Rejected Programs
Examine `reject1.rs` through `reject5.rs`:
- `reject1.rs`: Moved into collection (`vec![key]`), then used.
- `reject2.rs`: Two overlapping mutable borrows (`a` and `b`).
- `reject3.rs`: Mutable operation (`hosts.clear()`) while immutable reference `first` is live.
- `reject4.rs`: Returning a reference `&tag` to stack-allocated local variable `tag`.
- `reject5.rs`: Borrowing `&tmp` inside inner block where `tmp` goes out of scope before `survivor` is printed.

### 2. Record Matrix Answers in `answers.txt`
In `answers.txt`, set pairs `e1`/`c1` through `e5`/`c5`:

### Cause Options for `c1`–`c5`:
- `a`: a value was moved and then used
- `b`: two mutable borrows alive at once
- `c`: a mutable borrow while a shared borrow is still live
- `d`: returns a reference to a value that dies inside the function
- `e`: a reference outlives the value it points at (its scope ends first)

### 3. Verify Compiler Outputs
Run `rustc` against each program to verify your predictions:
```bash
rustc reject1.rs
rustc reject2.rs
rustc reject3.rs
rustc reject4.rs
rustc reject5.rs
```

### 4. Apply Minimal Fix to `reject5.rs`
Copy `reject5.rs` to `fixed5.rs`. Move `let tmp = String::from("short-lived");` out of the inner block (delete the inner `{ ... }` braces) so `tmp` outlives `survivor`.
Compile and run:
```bash
rustc fixed5.rs -o fixed5 && ./fixed5
```

### Graded Answer Format (`answers.txt`)
```txt
e1=E0382
c1=a
e2=E0499
c2=b
e3=E0502
c3=c
e4=E0515
c4=d
e5=E0597
c5=e
```
