fn main() {
    let mut counters = vec![1, 2, 3];
    let first = &mut counters[0];
    let second = &mut counters[1];
    *first += 10;
    *second += 10;
    println!("{counters:?}");
}
