// iocscan.rs — a toy IOC (indicator-of-compromise) line scanner. It compiles,
// it is memory-safe, and it runs on the sample input. It also contains six
// planted security flaws spanning Phase 4. Find them all. (Line references in
// the answer key are to THIS file as shipped — do not reformat it.)
use std::collections::HashMap;
use std::path::{Path, PathBuf};

// ---- config ----
const MAX_LINE_BYTES: u16 = 4096;

// FLAW A (CWE-197): declared_len arrives as u32 but is truncated to u16 before
// the size gate, so a value whose low 16 bits are small passes however large.
fn within_limit(declared_len: u32) -> bool {
    (declared_len as u16) <= MAX_LINE_BYTES
}

// FLAW B (CWE-22): the report path is built by joining a caller-supplied name
// onto the base directory with no containment check.
fn report_path(base: &str, name: &str) -> PathBuf {
    Path::new(base).join(name)
}

// FLAW C (CWE-78 pattern): a lookup command is assembled as a shell string from
// an untrusted indicator. Shown as the vulnerable shape; never executed here.
fn enrich_command(indicator: &str) -> String {
    format!("whois {indicator}")
}

// FLAW D (CWE-248): parses a "key:count" record and unwraps every step, so any
// malformed line crashes the whole scan.
fn parse_count(record: &str) -> (String, u32) {
    let (key, count) = record.split_once(':').unwrap();
    let n: u32 = count.parse().unwrap();
    (key.to_string(), n)
}

// FLAW E (logic bug): severity classification has an inverted threshold — a
// higher score should be MORE severe, but the comparison is backwards.
fn severity(score: u32) -> &'static str {
    if score < 10 {
        "critical"
    } else {
        "low"
    }
}

// FLAW F (CWE-190): total is a u16 accumulator over attacker-influenced counts;
// enough volume overflows it (panic in debug, silent wrap in release).
fn scan(records: &[&str]) -> String {
    let mut counts: HashMap<String, u32> = HashMap::new();
    let mut total: u16 = 0;
    for record in records {
        let (key, n) = parse_count(record);
        *counts.entry(key).or_insert(0) += 1;
        total += n as u16;
    }
    let mut keys: Vec<&String> = counts.keys().collect();
    keys.sort();
    format!("distinct = {}, total = {}", keys.len(), total)
}

fn main() {
    // good demo input — nothing here triggers the flaws, so the tool runs clean
    let records = ["scan:3", "auth:5", "scan:2"];
    println!("{}", scan(&records));

    println!("within_limit(512) = {}", within_limit(512));
    println!("report = {}", report_path("/srv/out", "daily.txt").display());
    println!("enrich = {}", enrich_command("scanme.example"));
    println!("severity(50) = {}", severity(50));
}
