thread::spawn with move gives each thread its own data; join returns its value as a Result
a bare shared borrow across a thread boundary is a data race — the compiler refuses it with E0373 (CWE-362)
determinism rule: grade sums or totals over joins, never the order threads happened to print
