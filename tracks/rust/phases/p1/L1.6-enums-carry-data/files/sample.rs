enum Event {
    Login { user: String, success: bool },
    PortScan { first: u16, last: u16 },
    Heartbeat,
}

fn describe(event: &Event) -> String {
    match event {
        Event::Login { user, success: true } => format!("login ok: {user}"),
        Event::Login { user, success: false } => format!("login FAIL: {user}"),
        Event::PortScan { first, last } => format!("scan {first}-{last}"),
        Event::Heartbeat => String::from("heartbeat"),
    }
}

fn main() {
    let feed = [
        Event::Login { user: String::from("root"), success: false },
        Event::PortScan { first: 1, last: 1024 },
        Event::Heartbeat,
    ];
    for event in &feed {
        println!("{}", describe(event));
    }
}
