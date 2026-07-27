fn banner(text: String) -> String {
    format!("== {text} ==")
}

fn main() {
    let title = String::from("scan report");
    let framed = banner(title);
    println!("{framed}");
    println!("original: {title}");
}
