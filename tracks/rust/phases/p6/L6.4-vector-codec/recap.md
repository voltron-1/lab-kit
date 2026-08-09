Vector decode path: raw bytes -> framed (delimiter/length) -> Result<Event> decode
decode is fallible by design — malformed input is an Err that is logged/dropped, never a panic
this is untrusted input at scale: bounded framing + non-panicking decode keep it from being a DoS
