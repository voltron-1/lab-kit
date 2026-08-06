FFI is the seam where Rust's guarantees stop — no borrow check, no lifetimes, no null safety
an extern signature is an unverified promise; a wrong one is instant undefined behavior
audit every FFI boundary as a trust boundary — the C side can violate every invariant
