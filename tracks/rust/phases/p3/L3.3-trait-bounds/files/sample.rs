use std::fmt::Display;

fn render<T: Display>(items: &[T]) -> String {
    let mut out = String::new();
    for item in items {
        out.push_str(&format!("[{item}]"));
    }
    out
}

fn largest<T: PartialOrd + Copy>(items: &[T]) -> T {
    let mut best = items[0];
    for &item in &items[1..] {
        if item > best {
            best = item;
        }
    }
    best
}

fn main() {
    let ports = [443u16, 22, 8443];
    println!("{}", render(&ports));
    println!("largest = {}", largest(&ports));

    let names = [String::from("ids"), String::from("edr")];
    println!("{}", render(&names));
}
