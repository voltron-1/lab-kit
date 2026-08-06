auditing unsafe = check every SAFETY invariant is real: pointers, lengths, lifetimes
a length read from input and trusted by from_raw_parts is an out-of-bounds read
a SAFETY comment is a claim to verify, not to trust — an unfulfilled one is a bug
