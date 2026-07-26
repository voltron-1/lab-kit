fn classify(port: u32) -> &'static str {
    if port < 1024 { "well-known" } else { "registered" }
}

fn main() {
    let x = {
        let a = 3;
        a * a
    };
    println!("x = {x}");

    let kind = classify(443);
    println!("kind = {kind}");

    let parity = if x % 2 == 0 { "even" } else { "odd" };
    println!("parity = {parity}");
}
