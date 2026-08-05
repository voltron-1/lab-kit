## BRIEF
`HashMap` and `Vec` are ubiquitous in Rust. Key patterns to recognize:
1. **Entry API**: `*counts.entry(k).or_insert(0) += 1` is the get-or-create counting idiom. `entry()` returns an entry slot; `or_insert()` initializes it if vacant; `*` dereferences the entry reference to mutate the value in place.
2. **Assertive Indexing vs. Fallible `.get()`**: Indexing (`counts["login"]`) panics if the key is missing. `.get("ghost")` returns an `Option<&V>`, allowing explicit handling (`unwrap_or(0)`).
3. **Iteration Order**: `HashMap` iteration order is unspecified and varies across executions. Collect keys into a `Vec` and sort them before printing or asserting output.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` with your answers to the following questions:
   - `q1`: What does `*counts.entry(event).or_insert(0) += 1` do?
     - `a`: Inserts 0 every time
     - `b`: Gets or creates the slot initialized to 0, then increments in place
     - `c`: Panics if key is absent
   - `q2`: What is the printed count for `login`?
   - `q3`: Why use `.get("ghost").unwrap_or(0)` instead of `counts["ghost"]`?
     - `a`: Style preference
     - `b`: Indexing panics on missing keys; `.get()` makes the fallback policy explicit
     - `c`: `.get()` is faster
   - `q4`: Why does the code sort `kinds` before printing?
     - `a`: `HashMap` iteration order is unspecified; sorting is required for deterministic output
     - `b`: `collect()` requires sorting
     - `c`: Alphabetical order is faster
   - `q5`: What value is printed for `ghost`?

Format `answers.txt`:
```text
q1=b
q2=3
q3=b
q4=a
q5=0
```

4. Verify with `lab check rust L3.7`.
