use std::sync::Arc;
use std::thread;

fn main() {
    // Arc<T> is Send + Sync (when T is): it can cross thread boundaries.
    let shared = Arc::new(vec![10u32, 20, 30]);

    let clone = Arc::clone(&shared);
    let handle = thread::spawn(move || {
        // read-only access from another thread — Sync makes &Arc shareable
        clone.iter().sum::<u32>()
    });

    let from_thread = handle.join().unwrap();
    let from_main: u32 = shared.iter().sum();
    println!("from_thread = {from_thread}");
    println!("from_main = {from_main}");
    println!("strong_count = {}", Arc::strong_count(&shared));
}
