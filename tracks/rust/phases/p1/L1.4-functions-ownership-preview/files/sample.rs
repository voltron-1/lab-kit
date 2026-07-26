fn shout(message: &str) -> String {
    message.to_uppercase()
}

fn consume(message: String) -> usize {
    message.len()
}

fn main() {
    let alert = String::from("port scan detected");
    let loud = shout(&alert);
    println!("{loud}");

    let size = consume(alert);
    println!("{size} bytes");

    // step 4: uncomment the next line, recompile, read the error, re-comment it
    // println!("{alert}");
}
