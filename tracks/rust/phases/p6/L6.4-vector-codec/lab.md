## BRIEF
In Vector, codecs handle parsing raw input bytes into structured events.

Because input from the network or disk is untrusted, decoders return `Result<T, DecodeError>`. Malformed input generates an `Err` that is logged and dropped — preventing a crash/panic DoS (L4.5).

## GUIDED STEPS

1. Inspect `files/vector-src/codec.rs`.
2. Notice the return signature of `decode`: `Result<Option<String>, DecodeError>`.
3. Observe how bad input returns `Err(DecodeError::InvalidJson)` rather than calling `.unwrap()`.
4. Create `answers.txt`:
   - `q1`: Framing does:
     - `a`: Decodes JSON
     - `b`: Splits a continuous byte stream into discrete frames before decoding
     - `c`: Opens sockets
   - `q2`: The decode method returns a:
     - `a`: Plain Event, panicking on bad input
     - `b`: `Result<Option<String>, DecodeError>` — decode is fallible
     - `c`: Bool
   - `q3`: A malformed record hitting the decoder will:
     - `a`: Panic the pipeline
     - `b`: Produce an `Err` that is handled/dropped so ingest survives
     - `c`: Be accepted silently
   - `q4`: What is the name of the decode function in `codec.rs`? -> `decode`
   - `q5`: The two controls that prevent hostile input from causing DoS here are:
     - `a`: Unsafe and speed
     - `b`: Bounded framing step and a fallible, non-panicking decode
     - `c`: A mutex and retry loop

Format `answers.txt`:
```text
q1=b
q2=b
q3=b
q4=decode
q5=b
```

5. Verify with `lab check rust L6.4`.
