// READ-ONLY EXHIBIT. Audit it.
use std::fs;
fn load_max_conns(path: &str) -> u16 {
    let text = fs::read_to_string(path).unwrap(); // FLAW 1: unwrap on I/O (CWE-248)
    let raw: u32 = text.trim().parse().unwrap();
    raw as u16                                    // FLAW 2: as truncation (CWE-197)
}
