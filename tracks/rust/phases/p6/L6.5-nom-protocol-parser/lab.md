## BRIEF
`nom` is the leading parser-combinator library in Rust. Security tools (like Suricata and Rusticata) use `nom` to parse protocol headers safely.

`nom` functions return `IResult<&[u8], Output>`, threading remaining input bytes forward. Combinators like `take(n)` perform automatic bounds checking, returning an `Err` on short input instead of out-of-bounds memory reads.

## GUIDED STEPS

1. Inspect `files/nom-parser-src/parser.rs`.
2. Observe `IResult<&[u8], Record>` returned by `parse_record`.
3. Locate `take(count)` — notice how `if i.len() < count` returns `Err("Incomplete")` rather than reading past the slice bound.
4. Create `answers.txt`:
   - `q1`: A nom parser function returns:
     - `a`: The value only
     - `b`: `IResult` — remaining input slice plus parsed value (or error)
     - `c`: Bool
   - `q2`: What is the name of the combinator in `parser.rs` that consumes N bytes with bounds checking? -> `take`
   - `q3`: When input is shorter than expected, `take(200)` will:
     - `a`: Read out of bounds
     - `b`: Return Incomplete/Err — refusing without an OOB read
     - `c`: Panic
   - `q4`: Compared to unsafe `from_raw_parts`, a nom parser is safe because:
     - `a`: Written in C
     - `b`: `take` bounds-checks length before consuming — hostile length is a handled parse error
     - `c`: Uses more unsafe
   - `q5`: What is the struct name of the parsed record type returned by `parse_record`? -> `Record`

Format `answers.txt`:
```text
q1=b
q2=take
q3=b
q4=b
q5=Record
```

5. Verify with `lab check rust L6.5`.
