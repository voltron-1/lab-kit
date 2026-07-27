# L2.9 — Borrow-error triage II — lifetimes in errors

## BRIEF
- Triage three lifetime-flavored compiler rejections: E0106 (missing lifetime specifier), E0515 (returning local reference), and E0597 (borrow outlives value).
- Record each error code and cause letter in `answers.txt`.
- Apply canonical fixes in `fixed1.rs`, `fixed2.rs`, and `fixed3.rs`.
- Learn the canonical escape routes: annotate the function contract (E0106), return an owned value (E0515), or align object scopes (E0597).

## GUIDED STEPS

### 1. Triage `broken1.rs` (Missing lifetime specifier)
Compile `broken1.rs`:
```bash
rustc broken1.rs
```
Observe `E0106`: the compiler refuses to guess whether the returned `&str` borrows from `line` or `fallback`.

In `answers.txt`, set:
- `e1`: `E0106`
- `c1`: the root cause letter from the cause options below

**Fix for `fixed1.rs`:**
Copy `broken1.rs` to `fixed1.rs`. Write the lifetime contract into the signature: `fn first_token<'a>(line: &'a str, fallback: &'a str) -> &'a str`.
Compile and run:
```bash
rustc fixed1.rs -o fixed1 && ./fixed1
```

### 2. Triage `broken2.rs` (Returning reference to local)
Compile `broken2.rs`:
```bash
rustc broken2.rs
```
Observe `E0515`: `full` is created on the stack inside `stamp` and destroyed on return, making returning `&full` illegal under any lifetime annotation.

In `answers.txt`, set:
- `e2`: `E0515`
- `c2`: the root cause letter from the cause options below

**Fix for `fixed2.rs`:**
Copy `broken2.rs` to `fixed2.rs`. Use the canonical escape: return an **owned** value. Update the return type to `String` (`fn stamp(prefix: &str) -> String`) and return `format!("{prefix}-4097")` directly.
Compile and run:
```bash
rustc fixed2.rs -o fixed2 && ./fixed2
```

### 3. Triage `broken3.rs` (Borrow outlives value)
Compile `broken3.rs`:
```bash
rustc broken3.rs
```
Observe `E0597`: `batch` is dropped at the end of the inner block while `newest` remains live.

In `answers.txt`, set:
- `e3`: `E0597`
- `c3`: the root cause letter from the cause options below

**Fix for `fixed3.rs`:**
Copy `broken3.rs` to `fixed3.rs`. Align object scopes: lift `let batch = String::from("evt-9911");` out of the inner block (delete the inner `{ ... }` braces) so `batch` lives as long as `newest`.
Compile and run:
```bash
rustc fixed3.rs -o fixed3 && ./fixed3
```

---

### Cause Options for `c1`, `c2`, `c3`:
- `a`: the signature won't say whose lifetime the output borrows
- `b`: returning a reference to a value that dies inside the function
- `c`: a reference outliving the value it points at

### Graded Answer Format (`answers.txt`)
```txt
e1=E0106
c1=a
e2=E0515
c2=b
e3=E0597
c3=c
```
