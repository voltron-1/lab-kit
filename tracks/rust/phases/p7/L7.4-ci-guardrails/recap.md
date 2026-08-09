four gates: clippy pedantic -D warnings, cargo audit, cargo deny, cargo test
audit catches known CVEs, deny enforces policy, clippy -D warnings blocks lint regressions
none catch logic bugs — CI gates are necessary, not sufficient; human review still ships
