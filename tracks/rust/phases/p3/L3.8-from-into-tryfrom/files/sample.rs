use std::convert::TryFrom;

fn main() {
    let small: u16 = 8443;
    let wide: u32 = u32::from(small);
    let wide2: u32 = small.into();
    println!("wide = {wide}, wide2 = {wide2}");

    let big: u32 = 70000;
    match u16::try_from(big) {
        Ok(port) => println!("fits: {port}"),
        Err(err) => println!("refused: {err}"),
    }

    let clamped = u16::try_from(big).unwrap_or(u16::MAX);
    println!("clamped = {clamped}");

    let truncated = big as u16;
    println!("truncated = {truncated}");
}
