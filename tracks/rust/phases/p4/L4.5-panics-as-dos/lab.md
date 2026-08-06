## BRIEF
Memory safety does **not** guarantee availability. Uncaught panics on attacker-reachable input paths crash the process, causing a Denial of Service (**CWE-248**).

Panics arise from multiple constructs:
1. `unwrap()` / `expect()` on `None` or `Err`.
2. Out-of-bounds array indexing or slice slicing (`&field[..3]`).
3. Integer overflow in debug mode (`total += n`, **CWE-190**).
4. Division by zero.

Audit rule: Identify panic paths reachable by untrusted input and replace them with panic-free accessors (`.get(..)`), fallible parsing (`?` / `unwrap_or`), and checked arithmetic (`checked_add`).

## GUIDED STEPS

1. Inspect `files/parse.rs`.
2. Compile `files/parse.rs` to `./parse`:
   ```bash
   rustc files/parse.rs -o parse
   ```
3. Test happy path:
   ```bash
   ./parse "scan=5" "auth=3"
   ```
4. Detonate an argument missing `=` to trigger a panic, capturing stderr:
   ```bash
   ./parse "nodelim" 2> panic1.txt || true
   ```
5. Create `answers.txt` answering the following audit questions:
   - `q1`: How many distinct panic risk sites (kinds) exist in `parse.rs`? -> `4`
   - `q2`: Which site panics when passed the argument `"nodelim"`?
     - `a`: `count.parse().unwrap()`
     - `b`: `arg.split_once('=').unwrap()`
     - `c`: `&field[..3]`
   - `q3`: What security risk class does an unhandled panic on an input path represent?
     - `a`: Memory corruption
     - `b`: Denial of service — an uncaught panic terminates the process (CWE-248)
     - `c`: Information disclosure
   - `q4`: Which site panics on integer overflow in debug mode (CWE-190)?
     - `a`: `&field[..3]`
     - `b`: `total += n`
     - `c`: `count.parse()`
   - `q5`: What is the panic-free replacement for slice indexing `&field[..3]`?
     - `a`: `unwrap()`
     - `b`: `field.get(..3)` returning `Option<&str>`
     - `c`: `field as u16`

Format `answers.txt`:
```text
q1=4
q2=b
q3=b
q4=b
q5=b
```

6. Verify with `lab check rust L4.5`.
