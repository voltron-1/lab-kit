# L2.5 — Borrow-error triage I — E0382, E0499, E0502

## BRIEF
- Triage three real compiler rejections: E0382 (moved-then-used), E0499 (two writers), and E0502 (writer-while-readers).
- Record each error code and underlying root cause in `answers.txt`.
- Apply the required minimal fix for each file in `fixed1.rs`, `fixed2.rs`, and `fixed3.rs`.
- Forbidden: do not use `.clone()` in `fixed1.rs` — borrow instead of copying!
- Note: `broken3.rs` illustrates the classic iterator-invalidation pattern that C++ allows to silently dangle.

## GUIDED STEPS

### 1. Triage `broken1.rs` (Moved value used after move)
Compile `broken1.rs` to observe the rejection:
```bash
rustc broken1.rs
```
Observe the compiler error tag (`E0382`) and notice that `title` was moved when passed by value into `banner`.

In `answers.txt`, set:
- `e1`: the error code (e.g. `E0382`)
- `c1`: the root cause letter from the cause options below

**Minimal Fix for `fixed1.rs`:**
Copy `broken1.rs` to `fixed1.rs`. Update `banner` to take a borrowed slice `text: &str` and pass `&title` at the call site.
Do NOT use `.clone()`.
Compile and run:
```bash
rustc fixed1.rs -o fixed1 && ./fixed1
```

### 2. Triage `broken2.rs` (Two mutable borrows)
Compile `broken2.rs`:
```bash
rustc broken2.rs
```
Observe `E0499`: two mutable borrows of `counters` overlapping in scope.

In `answers.txt`, set:
- `e2`: the error code (e.g. `E0499`)
- `c2`: the root cause letter from the cause options below

**Minimal Fix for `fixed2.rs`:**
Copy `broken2.rs` to `fixed2.rs`. Sequence the operations so that `first` is used before `second` is created (reordering so the first `&mut` borrow ends before the second begins).
Compile and run:
```bash
rustc fixed2.rs -o fixed2 && ./fixed2
```

### 3. Triage `broken3.rs` (Writer while reader lives)
Compile `broken3.rs`:
```bash
rustc broken3.rs
```
Observe `E0502`: `log.push(...)` requires a mutable borrow of `log` while `last` (an immutable borrow of `log[0]`) is still live.

In `answers.txt`, set:
- `e3`: the error code (e.g. `E0502`)
- `c3`: the root cause letter from the cause options below

**Minimal Fix for `fixed3.rs`:**
Copy `broken3.rs` to `fixed3.rs`. Reorder by moving `println!("last = {last}");` above `log.push(...)` so the immutable borrow's last use occurs before `push`.
Compile and run:
```bash
rustc fixed3.rs -o fixed3 && ./fixed3
```

---

### Cause Options for `c1`, `c2`, `c3`:
- `a`: a value was moved and then used
- `b`: two mutable borrows alive at once
- `c`: a mutable borrow while a shared borrow is still live

### Graded Answer Format (`answers.txt`)
```txt
e1=E0382
c1=a
e2=E0499
c2=b
e3=E0502
c3=c
```
