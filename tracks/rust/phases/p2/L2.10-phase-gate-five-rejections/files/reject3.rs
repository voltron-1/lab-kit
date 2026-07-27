fn main() {
    let mut hosts = vec![String::from("db-01")];
    let first = &hosts[0];
    hosts.clear();
    println!("gone but readable? {first}");
}
