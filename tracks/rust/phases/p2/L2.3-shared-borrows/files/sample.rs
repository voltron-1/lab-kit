fn longest_len(a: &String, b: &String) -> usize {
    if a.len() > b.len() { a.len() } else { b.len() }
}

fn main() {
    let host = String::from("bastion-01");
    let alias = &host;
    let alias2 = &host;
    println!("{alias} / {alias2} / {host}");

    let primary = String::from("core-router");
    let backup = String::from("edge-fw");
    let max = longest_len(&primary, &backup);
    println!("max = {max}");
    println!("{primary} + {backup} still here");
}
