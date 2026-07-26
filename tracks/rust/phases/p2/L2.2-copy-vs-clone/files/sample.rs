#[derive(Clone, Copy)]
struct PortRange {
    first: u16,
    last: u16,
}

fn width(range: PortRange) -> u16 {
    range.last - range.first
}

fn main() {
    let a = 41;
    let b = a;
    println!("a = {a}, b = {b}");

    let scan = PortRange { first: 20, last: 25 };
    let w = width(scan);
    println!("w = {w}");
    println!("scan.first = {}", scan.first);

    let name = String::from("dmz-probe");
    let copy_of_name = name.clone();
    println!("{name} / {copy_of_name}");
}
