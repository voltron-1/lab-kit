a spec that produces safe Rust constrains failure behavior, not just the happy path
name the load-bearing four: return Result, validate range, no panic on input, reject junk
exclude the anti-patterns — as truncation, unwrap-on-input, mutable globals — on purpose
