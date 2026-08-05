fn main() {
    let ports: Vec<u32> = vec![21, 22, 443, 8080, 9200];

    let total: u32 = ports.iter().sum();
    println!("total = {total}");

    let high: Vec<u32> = ports.iter().copied().filter(|p| *p > 1000).collect();
    println!("high = {high:?}");

    let doubled: Vec<u32> = high.iter().map(|p| p * 2).collect();
    println!("doubled = {doubled:?}");

    let low_count = ports.iter().filter(|p| **p < 100).count();
    println!("low_count = {low_count}");

    let lazy = ports.iter().map(|p| p * 10);
    println!("adapters built, nothing computed yet");
    let scaled: Vec<u32> = lazy.collect();
    println!("first = {}", scaled[0]);
}
