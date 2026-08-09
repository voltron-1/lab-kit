// draft_v1.rs — READ-ONLY EXHIBIT.
use serde_json::json;
fn to_ecs(line: &str) -> String {
    let parts: Vec<&str> = line.split(' ').collect();
    let ts = parts[0];                                  // FLAW 1: unchecked indexing (CWE-248)
    let dataset = parts[1];
    let outcome = parts[2];                             // FLAW 3: raw OK/FAILED, not success/failure
    let user = parts[3].strip_prefix("user=").unwrap(); // FLAW 2: unwrap on None (CWE-248)
    let src = parts[4].strip_prefix("src=").unwrap();
    json!({
        "@timestamp": ts,
        "event.dataset": dataset,
        "event.outcome": outcome,
        "user.name": user,
        "source.ip": src,
        "message": line
    }).to_string()
}
fn main() {
    for line in std::io::stdin().lines() {
        println!("{}", to_ecs(&line.unwrap()));         // FLAW 4: unwrap per line (CWE-248)
    }
}
