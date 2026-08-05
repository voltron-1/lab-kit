## BRIEF
Iterator chains are lazy adapter pipelines in Rust:
1. **Source**: `.iter()` (borrows items as `&T`), `.into_iter()` (moves items `T`), or `.iter_mut()` (borrows mutably `&mut T`).
2. **Adapters**: `.filter()`, `.map()`, `.copied()`, `.take()` — these build lazy pipeline stages; **nothing is evaluated yet**.
3. **Terminal Consumer**: `.collect()`, `.sum()`, `.count()`, `.fold()` — single terminal call that pulls elements through the pipeline.

Notice `filter` takes a reference to each item. Over `.iter()` (which yields `&u32`), `filter`'s parameter is `&&u32`, requiring `**p` to dereference down to `u32`.

## GUIDED STEPS

1. Inspect `files/sample.rs` and predict its behavior without running it first.
2. Create `predictions.txt` with your predictions:
   - `total`: sum of all 5 initial ports (`21, 22, 443, 8080, 9200`) -> `total=17766`
   - `hi`: first element of `high` (ports `> 1000`) -> `hi=8080`
   - `low_count`: count of ports `< 100` -> `low_count=2`
   - `first`: first element of `scaled` (`scaled[0]`, which is `21 * 10`) -> `first=210`

Format `predictions.txt`:
```text
total=17766
hi=8080
low_count=2
first=210
```

3. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
4. Verify with `lab check rust L3.5`.
