fn register(tag: String) -> usize {
    tag.len()
}

fn main() {
    let alpha = String::from("intrusion");
    let beta = alpha;
    println!("beta = {beta}");

    let gamma = String::from("port-22");
    let size = register(gamma);
    println!("size = {size}");

    let delta = beta.clone();
    println!("delta = {delta}");
    println!("beta again = {beta}");
}
