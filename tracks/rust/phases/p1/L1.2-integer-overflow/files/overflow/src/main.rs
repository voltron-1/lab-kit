fn bump(n: u8) -> u8 {
    n + 1
}

fn main() {
    let max: u8 = u8::MAX;
    println!("max = {max}");
    println!("checked = {:?}", max.checked_add(1));
    println!("wrapped = {}", max.wrapping_add(1));
    println!("bumped = {}", bump(max));
}
