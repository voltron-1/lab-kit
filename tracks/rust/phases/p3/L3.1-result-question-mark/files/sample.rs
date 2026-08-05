use std::num::ParseIntError;

fn parse_port(raw: &str) -> Result<u16, ParseIntError> {
    let port: u16 = raw.trim().parse()?;
    Ok(port)
}

fn describe(raw: &str) -> String {
    match parse_port(raw) {
        Ok(port) => format!("{raw} -> port {port}"),
        Err(err) => format!("{raw} -> refused ({err})"),
    }
}

fn main() {
    println!("{}", describe("443"));
    println!("{}", describe("70000"));
    println!("{}", describe("http"));
}
