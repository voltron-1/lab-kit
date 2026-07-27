fn stamp(prefix: &str) -> &str {
    let full = format!("{prefix}-4097");
    &full
}

fn main() {
    println!("{}", stamp("sess"));
}
