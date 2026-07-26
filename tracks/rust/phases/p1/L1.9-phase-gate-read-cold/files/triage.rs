// triage.rs — Phase 1 gate. Read it cold. Answer the 10 questions in
// answers.txt BEFORE you compile it. Then run it to self-check.

#[derive(Debug)]
enum Verdict {
    Benign,
    Suspicious,
    Hostile,
}

struct Source {
    name: String,
    failures: u8,
    internal: bool,
}

fn service_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        "rdp" => Some(3389),
        _ => None,
    }
}

fn judge(source: &Source) -> Verdict {
    let score = {
        let base = if source.internal { 0 } else { 2 };
        base + source.failures / 3
    };
    if score == 0 {
        Verdict::Benign
    } else if score < 4 {
        Verdict::Suspicious
    } else {
        Verdict::Hostile
    }
}

fn main() {
    let sources = [
        Source { name: String::from("build-server"), failures: 2, internal: true },
        Source { name: String::from("laptop-7"), failures: 9, internal: true },
        Source { name: String::from("203.0.113.9"), failures: 7, internal: false },
    ];

    let mut hostile_count = 0;
    let mut total: u8 = 0;
    for source in &sources {
        let verdict = judge(source);
        println!("{} -> {:?}", source.name, verdict);
        if let Verdict::Hostile = verdict {
            hostile_count += 1;
        }
        total += source.failures;
    }
    println!("hostile: {hostile_count}");
    println!("total failures: {total}");

    let target = service_port("rdp").unwrap_or(0);
    println!("watch port {target}");
}
