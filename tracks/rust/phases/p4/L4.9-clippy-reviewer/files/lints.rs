// lints.rs — this compiles and runs. Run clippy on it and read what it flags.
fn risk_score(events: &Vec<u32>) -> u32 {   // clippy: ptr_arg (&Vec -> &[])
    let mut sum = 0;
    for i in 0..events.len() {               // clippy: needless_range_loop
        sum = sum + events[i];               // clippy: could be += ; indexing
    }
    if sum > 100 {
        return true as u32;                  // clumsy; clippy may flag
    }
    return sum;                              // clippy: needless_return
}

fn main() {
    let events = vec![10u32, 20, 30];
    let total: u32 = events.iter().map(|x| x * 1).sum();  // clippy: identity_op (* 1)
    println!("score = {}", risk_score(&events));
    println!("total = {total}");
}
