fn scheme(url: &str) -> &str {
    match url.find("://") {
        Some(index) => &url[..index],
        None => "unknown",
    }
}

fn main() {
    let owned = String::from("https://vault:8443");
    let borrowed: &str = &owned;

    println!("scheme = {}", scheme(&owned));
    println!("scheme = {}", scheme("ldap://dc-01"));
    println!("len = {}", borrowed.len());

    let literal = "tcp/443";
    let proto = &literal[..3];
    println!("proto = {proto}");
}
