String owns heap and grows; &str is a borrowed view — parameters want &str
&String coerces to &str at call sites automatically (deref coercion) — read past it
slices are zero-copy byte-offset views; a non-UTF-8-boundary cut panics at runtime
