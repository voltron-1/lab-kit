// READ-ONLY EXHIBIT. Audit it.
use std::path::Path;
use std::process::Command;
fn fetch(base: &str, name: &str) -> String {
    let p = Path::new(base).join(name);          // FLAW 1: path traversal (CWE-22)
    let out = Command::new("sh").arg("-c")
        .arg(format!("cat {}", p.display()))     // FLAW 2: command injection (CWE-78)
        .output().unwrap();
    String::from_utf8_lossy(&out.stdout).to_string()
}
