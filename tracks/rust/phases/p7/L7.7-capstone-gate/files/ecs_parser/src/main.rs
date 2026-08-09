// READ-ONLY EXHIBIT — the shipped capstone
use serde_json::json;
use std::io::BufRead;

fn to_ecs(line: &str) -> Option<String> {
    let parts: Vec<&str> = line.split(' ').collect();
    if parts.len() != 5 {
        return None;
    }
    let user = parts[3].strip_prefix("user=")?;
    let src = parts[4].strip_prefix("src=")?;
    let outcome = match parts[2] {
        "OK" => "success",
        "FAILED" => "failure",
        _ => return None,
    };
    Some(json!({
        "@timestamp": parts[0],
        "event.dataset": parts[1],
        "event.action": "login-attempt",
        "event.outcome": outcome,
        "user.name": user,
        "source.ip": src,
        "message": line
    }).to_string())
}

fn main() {
    let mut ok = 0u32;
    let mut skipped = 0u32;
    let stdin = std::io::stdin();
    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => { skipped += 1; continue; }
        };
        match to_ecs(&line) {
            Some(json) => { println!("{json}"); ok += 1; }
            None => { skipped += 1; }
        }
    }
    eprintln!("emitted {ok}, skipped {skipped}");
}
