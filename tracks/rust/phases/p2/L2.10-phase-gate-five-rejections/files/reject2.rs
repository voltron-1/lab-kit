fn main() {
    let mut score = 10;
    let a = &mut score;
    let b = &mut score;
    *a += 1;
    *b += 1;
    println!("score = {score}");
}
