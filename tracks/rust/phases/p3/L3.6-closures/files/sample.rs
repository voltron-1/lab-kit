fn main() {
    let threshold = 100;
    let is_high = |v: u32| v > threshold;
    println!("is_high(150) = {}", is_high(150));
    println!("threshold still = {threshold}");

    let mut streak = 0;
    let mut bump = || streak += 1;
    bump();
    bump();
    bump();
    println!("streak = {streak}");

    let tag = String::from("scan");
    let label = move |v: u32| format!("{tag}:{v}");
    println!("{}", label(9));
    println!("{}", label(10));
}
