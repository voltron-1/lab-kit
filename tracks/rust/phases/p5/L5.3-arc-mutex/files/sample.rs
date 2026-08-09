use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Arc = shared OWNERSHIP across threads; Mutex = synchronized ACCESS.
    let counter = Arc::new(Mutex::new(0u32));

    let mut handles = Vec::new();
    for _ in 0..4 {
        let c = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            for _ in 0..25 {
                let mut guard = c.lock().unwrap(); // acquire the lock
                *guard += 1;
            }                                      // guard drops here -> unlock
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("count = {}", *counter.lock().unwrap());
}
