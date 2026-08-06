use std::path::{Path, PathBuf};

// FLAW 1 (CWE-22, path traversal): joins user input onto a base directory with
// no containment check. A name like "../../etc/shadow" escapes `base` entirely.
fn resolve(base: &str, name: &str) -> PathBuf {
    Path::new(base).join(name)
}

// FLAW 2 (CWE-78, command injection PATTERN): builds a shell command string
// from user input and would hand it to `sh -c`. Shown as the vulnerable shape
// to RECOGNIZE — this lab does not execute it.
fn build_lookup_command(host: &str) -> String {
    format!("host {host}")   // interpolating untrusted `host` into a shell line
}

// FLAW 3 (logic bug): an access check that is inverted. Compiles, runs, memory-
// safe — and grants access to exactly the wrong callers.
fn may_read(is_admin: bool, is_locked: bool) -> bool {
    is_admin || is_locked   // BUG: a LOCKED account should be denied, not allowed
}

fn main() {
    // INERT demo of FLAW 1: show that the join escaped the base dir. No read.
    let escaped = resolve("/srv/reports", "../../etc/shadow");
    println!("resolved = {}", escaped.display());

    // FLAW 2: the string that WOULD be passed to a shell (never executed here).
    println!("would run: {}", build_lookup_command("scanme.example"));

    // FLAW 3: a locked, non-admin account is wrongly granted read.
    println!("locked non-admin may_read = {}", may_read(false, true));
}
