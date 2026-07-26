use scanport::parse_port;

fn main() {
    for raw in std::env::args().skip(1) {
        match parse_port(&raw) {
            Some(port) => println!("{raw} -> ok (port {port})"),
            None => println!("{raw} -> INVALID"),
        }
    }
}
