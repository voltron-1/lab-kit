extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    let a = abs(-9);
    println!("abs(-9) = {a}");
}
