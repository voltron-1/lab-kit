# Task: Spec a Safe Port Parser Function

Spec a function `parse_port(input: &str)` that turns a CLI string into a validated TCP port integer.

Candidate constraints:
a) Return a Result or Option so failure is a value, not a panic [ESSENTIAL]
b) Make it run as fast as possible
c) Reject ports outside 1..=65535 [ESSENTIAL]
d) Never unwrap/expect/panic on the input string [ESSENTIAL]
e) Convert with `as u16`
f) Reject non-numeric input with a clear error [ESSENTIAL]
g) Cache results in a mutable global
h) Add colored terminal output
