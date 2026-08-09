use std::thread;

fn main() {
    let mut handles = Vec::new();
    for id in 0..4u32 {
        handles.push(thread::spawn(move || {
            // each thread owns its own copy of id (moved in)
            id * 10
        }));
    }

    let mut total = 0;
    for handle in handles {
        total += handle.join().unwrap();
    }
    println!("total = {total}");
    println!("threads joined; result is order-independent");
}
