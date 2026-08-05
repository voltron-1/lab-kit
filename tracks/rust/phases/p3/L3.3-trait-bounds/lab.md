## BRIEF
A generic trait bound `<T: Display + Copy>` is a **capability contract**:
- The body of the function may only perform operations granted by those bounds (`Display` grants formatting, `Copy` grants value duplication out of references).
- A call site can only supply a type `T` that implements all listed traits.

If a concrete type is passed that lacks a required bound, Rust throws compile error **`E0277`** naming the exact missing trait.

## GUIDED STEPS

1. Inspect `files/sample.rs`. Notice how `render` requires `<T: Display>` and `largest` requires `<T: PartialOrd + Copy>`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Attempt to compile `files/broken.rs` (`rustc files/broken.rs`) to observe what happens when `String` (which does not implement `Copy`) is passed to `largest`.
4. Create `answers.txt` answering the following questions:
   - `q1`: What does `<T: Display>` mean in a function signature?
     - `a`: `T` is a String type
     - `b`: Any `T` the function body may format — the bound grants exactly that capability
     - `c`: `T` prints only in debug builds
   - `q2`: Why does `largest` require the `Copy` bound?
     - `a`: For performance optimization
     - `b`: `best = items[0]` duplicates out of a borrowed slice — without `Copy`, moving out of a borrow is illegal
     - `c`: By Rust coding style conventions
   - `q3`: What is the value of `largest` printed in `sample` output? -> `8443`
   - `q4`: What error code is produced when compiling `files/broken.rs`? -> `E0277`
   - `q5`: Which trait bound does `String` fail to satisfy when passed to `largest`?
     - `a`: `PartialOrd`
     - `b`: `Copy`
     - `c`: `Display`

Format `answers.txt`:
```text
q1=b
q2=b
q3=8443
q4=E0277
q5=b
```

5. Verify with `lab check rust L3.3`.
