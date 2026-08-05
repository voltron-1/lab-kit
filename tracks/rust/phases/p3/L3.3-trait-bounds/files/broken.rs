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
    let names = [String::from("ids"), String::from("edr")];
    println!("{}", largest(&names));
}
