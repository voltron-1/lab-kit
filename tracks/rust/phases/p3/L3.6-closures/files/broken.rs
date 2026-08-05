fn main() {
    let tag = String::from("scan");
    let label = move |v: u32| format!("{tag}:{v}");
    println!("{}", label(7));
    println!("tag = {tag}");
}
