fn find_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        "https" => Some(443),
        "dns" => Some(53),
        _ => None,
    }
}

fn main() {
    println!("{:?}", find_port("ssh"));
    println!("{:?}", find_port("gopher"));

    let fallback = find_port("telnet").unwrap_or(0);
    println!("fallback = {fallback}");

    if let Some(port) = find_port("dns") {
        println!("dns runs on {port}");
    }
}
