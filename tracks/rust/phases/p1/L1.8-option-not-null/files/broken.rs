fn find_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        _ => None,
    }
}

fn main() {
    let port: u16 = find_port("ssh");
    println!("port = {port}");
}
