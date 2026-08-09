## BRIEF
Vector is a high-performance observability data pipeline in Rust. Its architecture mirrors Logstash:
- **Source**: Ingests raw events (input)
- **Transform**: Reshapes, filters, or enriches events (filter)
- **Sink**: Emits events to external systems (output)

## GUIDED STEPS

1. Inspect `files/vector-src/topology.rs`.
2. Locate the `Event` type that flows through the pipeline.
3. Observe how `Transform::transform` returns a `Vec<Event>`, allowing it to yield zero (dropped), one, or multiple events.
4. Create `answers.txt`:
   - `q1`: Vector's three pipeline stages in order, comma-separated (lowercase)? -> `source,transform,sink`
   - `q2`: Mapping to Logstash: source / transform / sink correspond to:
     - `a`: output/filter/input
     - `b`: input/filter/output
     - `c`: codec/pipeline/buffer
   - `q3`: A Transform can turn one input event into:
     - `a`: Exactly one output always
     - `b`: Zero, one, or many events
     - `c`: Only metrics
   - `q4`: What is the name of the struct type that flows through the pipeline? -> `Event`
   - `q5`: The pipeline topology is wired together by:
     - `a`: Hardcoded Rust code
     - `b`: A config file (TOML/YAML) naming sources, transforms, and sinks
     - `c`: CLI flags only

Format `answers.txt`:
```text
q1=source,transform,sink
q2=b
q3=b
q4=Event
q5=b
```

5. Verify with `lab check rust L6.3`.
