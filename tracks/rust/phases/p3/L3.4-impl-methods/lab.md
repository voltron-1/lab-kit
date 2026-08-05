## BRIEF
In Rust, `impl` blocks separate type behavior from type data layout. Method signatures are contracts determined by their self receiver:
- `&self`: borrows immutably (read access)
- `&mut self`: borrows mutably (write access, requires `mut` variable binding)
- `self`: consumes/moves ownership (`self` is moved into the method and dead afterwards)

Method syntax (`auth.record()`) is syntactic sugar for associated function calls (`Tally::record(&mut auth)`).

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Conduct the experiment: temporarily add `println!("{}", auth.report());` at the marked line in `files/sample.rs` after `auth.into_label()`. Attempt to compile (`rustc files/sample.rs`). Note the error code (`E0382`: borrow of moved value). Then remove the extra line and recompile `files/sample.rs`.
4. Create `answers.txt` answering the following:
   - `q1`: Why does `record()` take `&mut self`?
     - `a`: It mutates a field (`self.hits += 1`) — requiring writer access
     - `b`: For execution speed
     - `c`: Coding style preference
   - `q2`: What does bare `self` in `into_label(self)` signify?
     - `a`: Immutable borrow
     - `b`: The method call consumes the instance — `auth` is moved and dead afterwards
     - `c`: Deep copy
   - `q3`: The exact string printed by `auth.report()` in the initial output -> `failed-auth: 3 hits`
   - `q4`: The compiler error code from the experiment in step 3 -> `E0382`
   - `q5`: `auth.record()` desugars to which associated function call?
     - `a`: `Tally::record(&mut auth)`
     - `b`: `record(auth)`
     - `c`: `auth::record()`

Format `answers.txt`:
```text
q1=a
q2=b
q3=failed-auth: 3 hits
q4=E0382
q5=a
```

5. Verify with `lab check rust L3.4`.
