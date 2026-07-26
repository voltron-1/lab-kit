#[derive(Debug)]
struct Endpoint {
    host: String,
    port: u16,
    tls: bool,
}

fn make_local(port: u16) -> Endpoint {
    Endpoint {
        host: String::from("127.0.0.1"),
        port,
        tls: false,
    }
}

fn main() {
    let a = make_local(8080);
    println!("a = {a:?}");

    let b = Endpoint {
        host: String::from("10.0.0.5"),
        ..a
    };
    println!("b = {b:?}");
    println!("a.host = {}", a.host);
}
