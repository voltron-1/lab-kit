fn read_flag(input: &str) -> u32 {
    let value: u32 = input.parse()?;
    value
}

fn main() {
    println!("{}", read_flag("7"));
}
