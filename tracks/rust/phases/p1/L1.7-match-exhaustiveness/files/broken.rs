enum Severity {
    Low,
    Medium,
    High,
    Critical,
}

fn action(level: Severity) -> &'static str {
    match level {
        Severity::Low => "log only",
        Severity::Medium => "open ticket",
        Severity::High => "page on-call",
    }
}

fn main() {
    let alerts = [
        Severity::Low,
        Severity::Medium,
        Severity::High,
        Severity::Critical,
    ];
    for level in alerts {
        println!("{}", action(level));
    }
}
