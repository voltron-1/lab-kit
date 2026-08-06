fn main() {
    let bytes = [10u8, 20, 30, 40];
    let byte = *bytes.get_unchecked(2);
    println!("byte = {byte}");
}
