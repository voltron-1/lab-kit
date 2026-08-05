use std::collections::HashMap;

fn main() {
    let events = ["login", "scan", "login", "probe", "login"];

    let mut counts: HashMap<&str, u32> = HashMap::new();
    for event in events {
        *counts.entry(event).or_insert(0) += 1;
    }

    println!("login = {}", counts["login"]);
    println!("scan = {}", counts.get("scan").copied().unwrap_or(0));
    println!("ghost = {}", counts.get("ghost").copied().unwrap_or(0));

    let mut kinds: Vec<&str> = counts.keys().copied().collect();
    kinds.sort();
    println!("kinds = {kinds:?}");
}
