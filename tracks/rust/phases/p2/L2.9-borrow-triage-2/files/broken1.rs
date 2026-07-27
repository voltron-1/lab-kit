fn first_token(line: &str, fallback: &str) -> &str {
    match line.split(',').next() {
        Some(token) => token,
        None => fallback,
    }
}

fn main() {
    let line = String::from("alert,high,4625");
    println!("{}", first_token(&line, "none"));
}
