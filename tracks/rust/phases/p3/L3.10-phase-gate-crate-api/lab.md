## BRIEF
This phase gate tests your ability to read a real crate's public API cold and answer questions directly from signatures, lifetime annotations, return types, and safety/performance contracts.

## GUIDED STEPS

1. Inspect `files/regex-api.txt` (Note: read-only API exhibit).
2. Create `answers.txt` with your answers to the 10 questions:
   - `q1`: Can constructing a `Regex` fail?
     - `a`: No
     - `b`: Yes — `Regex::new` returns `Result<Regex, Error>`
     - `c`: Only at match time
   - `q2`: What ownership/borrow contract does `is_match` specify?
     - `a`: Consumes the Regex
     - `b`: Returns `bool`, borrowing both the regex and the haystack with no ownership changes
     - `c`: Returns `Option<bool>`
   - `q3`: What does the `'h` lifetime parameter on `find<'h>` tie the returned `Match<'h>` to?
     - `a`: The `Regex` instance
     - `b`: The haystack string slice — `Match` is a zero-copy borrowed view into haystack
     - `c`: `'static`
   - `q4`: What does `captures()` return when nothing matches?
   - `q5`: What happens when accessing `caps[5]` via indexing for a group that did not participate?
     - `a`: Returns `""`
     - `b`: Panics — `Index` implementation is assertive access
     - `c`: Returns `None`
   - `q6`: What is the name of the panic-free method to safely retrieve a capture group by index?
   - `q7`: What is the security impact of feeding an untrusted pattern to `Regex::new`?
     - `a`: Risk of catastrophic backtracking DoS during search
     - `b`: Invalid syntax is rejected with `Err`, and search is guaranteed linear-time by design — primary concern is compile time/pattern size limits
     - `c`: Undefined behavior
   - `q8`: Why does `as_str()` return `&'h str` rather than a `String`?
     - `a`: `String` is deprecated
     - `b`: It is a zero-copy slice borrowing from haystack with no heap allocation
     - `c`: Legacy C API compatibility
   - `q9`: Which method name returns the byte offset where a `Match` begins?
   - `q10`: How is failure handling structured in this API design?
     - `a`: Functions panic everywhere on unexpected inputs
     - `b`: Constructors return `Result`, lookups return `Option`, and panics are isolated to assertive indexing (`Index`) — failure contracts live in the types

Format `answers.txt`:
```text
q1=b
q2=b
q3=b
q4=None
q5=b
q6=get
q7=b
q8=b
q9=start
q10=b
```

3. Verify with `lab check rust L3.10`.
