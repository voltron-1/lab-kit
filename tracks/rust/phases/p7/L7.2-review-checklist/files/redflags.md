# Red Flag Catalog

1. unwrap() on request/input data -> availability
2. an unsafe block with no // SAFETY comment -> memory-safety
3. len as u16 on an input-derived length -> input-validation
4. Path::new(base).join(user_input) with no containment -> input-validation
5. tokio::spawn in an unbounded accept loop -> availability
6. a dependency flagged by a RUSTSEC advisory -> supply-chain
7. a shell command built by string interpolation of input -> input-validation
8. a raw pointer dereference / from_raw_parts with an unchecked length -> memory-safety
