fn main() {
    let mut log = vec![String::from("boot")];
    let last = &log[0];
    log.push(String::from("login"));
    println!("last = {last}");
    println!("entries = {}", log.len());
}
