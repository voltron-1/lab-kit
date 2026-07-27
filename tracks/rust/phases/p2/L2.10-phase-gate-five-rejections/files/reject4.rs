fn label(kind: &str) -> &str {
    let tag = format!("[{kind}]");
    &tag
}

fn main() {
    println!("{}", label("scan"));
}
