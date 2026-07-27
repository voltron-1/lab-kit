# L2.8 — The C++ crime scene — use-after-free side-by-side

## BRIEF
- Audit a classic C++ memory corruption bug: CWE-416 (use-after-free via vector reallocation).
- Compare `crime.cpp` (read-only exhibit) with its line-for-line Rust equivalent `equivalent.rs`.
- Prove that Rust catches iterator invalidation at compile time before any binary is produced.
- Capture the compiler rejection output using `rustc equivalent.rs 2> rust_error.txt`.

## GUIDED STEPS

### 1. Read the C++ Exhibit (`crime.cpp`)
Read `crime.cpp`:
```cpp
// crime.cpp — READ-ONLY EXHIBIT. Do not compile; you are here to read.
#include <cstdio>
#include <vector>

int main() {
    std::vector<int> ports = {22, 80, 443};
    const int& first = ports[0];      // reference into vector buffer
    for (int p = 8000; p < 8032; ++p) {
        ports.push_back(p);           // reallocation frees original buffer!
    }
    std::printf("first = %d\n", first); // UNDEFINED BEHAVIOR: reads freed memory
    return 0;
}
```
Notice that C++ compilers accept this program without warnings or errors. At runtime, `push_back` may reallocate the vector's underlying heap storage, leaving `first` pointing to freed memory.

### 2. Capture the Rust Rejection Evidence
Inspect `equivalent.rs`, which mirrors `crime.cpp` line for line in safe Rust:
```rust
fn main() {
    let mut ports = vec![22, 80, 443];
    let first = &ports[0];
    for p in 8000..8032 {
        ports.push(p);
    }
    println!("first = {first}");
}
```
Attempt to compile `equivalent.rs` and redirect stderr to `rust_error.txt`:
```bash
rustc equivalent.rs 2> rust_error.txt
```
Notice that compilation fails with exit code 1. View `rust_error.txt` to find `error[E0502]`.

### 3. Record Answers in `answers.txt`
In `answers.txt`, set keys `q1` through `q5`:

- `q1`: What is the Common Weakness Enumeration ID for use-after-free (format `CWE-###`)?
- `q2`: Which line arms the vulnerability in `crime.cpp`?
  - `a`: Taking `first` — references to collection elements are always illegal
  - `b`: Calling `push_back`, which may reallocate the vector buffer while `first` still references it
  - `c`: The `std::printf` call
- `q3`: What error code is recorded in `rust_error.txt`? (e.g. `E0502`)
- `q4`: Which borrow rule blocked the bug in Rust?
  - `a`: Two `&mut` references cannot exist at once
  - `b`: `&mut` (`ports.push`) requested while an immutable `&` (`first`) is still live — Aliasing XOR Mutation
  - `c`: Missing lifetime parameter on `main`
- `q5`: When does C++ catch this use-after-free bug?
  - `a`: Compile time
  - `b`: Possibly never — it is runtime undefined behavior that may silently pass test runs
  - `c`: Link time

### Graded Answer Format (`answers.txt`)
```txt
q1=CWE-416
q2=b
q3=E0502
q4=b
q5=b
```
