#[derive(Clone, Copy)]
struct Session {
    id: u32,
    token: String,
}

fn main() {
    let s = Session { id: 7, token: String::from("abc") };
    println!("{} {}", s.id, s.token);
}
