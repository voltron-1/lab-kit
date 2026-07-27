fn main() {
    let mut ports = vec![22, 80, 443];
    let first = &ports[0];
    for p in 8000..8032 {
        ports.push(p);
    }
    println!("first = {first}");
}
