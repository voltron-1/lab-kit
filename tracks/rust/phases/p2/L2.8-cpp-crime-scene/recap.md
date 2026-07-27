CWE-416: the reference outlived the buffer — C++ compiles it and attackers exploit it
Rust makes the same shape E0502: growth needs &mut while the old & is still alive
this is the borrow checker's job description: memory-corruption bugs die pre-build
