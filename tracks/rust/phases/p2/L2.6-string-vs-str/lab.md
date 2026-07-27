# L2.6 — String vs &str, and slices

## BRIEF
- Read the owner/view split: `String` owns heap memory; `&str` is a borrowed, zero-copy view.
- Understand deref coercion: parameters taking `&str` accept `&String`, string literals, and string slices automatically.
- Analyze byte-offset slicing (`&url[..index]`) and note the security implication: indexing non-UTF-8 boundaries causes a runtime panic.
- Record answers in `answers.txt` and compile/run `sample.rs`.

## GUIDED STEPS

### 1. Read `sample.rs` and Predict behavior
Inspect `sample.rs`:
```rust
fn scheme(url: &str) -> &str {
    match url.find("://") {
        Some(index) => &url[..index],
        None => "unknown",
    }
}
```
Key observations:
- `scheme` takes `url: &str`.
- Calling `scheme(&owned)` relies on **deref coercion** (`&String` coerces to `&str`).
- Slicing `&url[..index]` produces a zero-copy view into the input buffer without allocation.

### 2. Answer Graded Questions in `answers.txt`
In `answers.txt`, provide answers for keys `q1` through `q5`:

- `q1`: What types of arguments does a parameter of type `&str` accept?
  - `a`: Only string literals (`&'static str`)
  - `b`: Only borrowed `String` references (`&String`)
  - `c`: Borrowed `String` references, literals, and slices — all of them
- `q2`: What scheme string is printed for the first URL (`https://vault:8443`)?
- `q3`: What string is printed for `proto` (`&literal[..3]`)?
- `q4`: What integer is printed for `len` (`borrowed.len()`)?
- `q5`: How much memory does `&url[..index]` allocate?
  - `a`: A new `String` heap buffer
  - `b`: Nothing — it is a borrowed view into the same buffer
  - `c`: A boxed heap copy

### 3. Compile and Run `sample.rs`
Compile and run `sample.rs`:
```bash
rustc sample.rs -o sample && ./sample
```

### Graded Answer Format (`answers.txt`)
```txt
q1=c
q2=https
q3=tcp
q4=18
q5=b
```
