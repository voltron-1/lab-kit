// ingest.rs — a tiny event-line ingester. It compiles. That is not the same
// as safe. Count the ways input can kill this process.
fn main() {
    let line = std::env::args().nth(1).unwrap();
    let (kind, size) = line.split_once(':').unwrap();
    let size: u32 = size.parse().unwrap();
    let tag = kind.get(..4).expect("kind at least 4 bytes");
    println!("{tag} accepted ({size} bytes)");
}
