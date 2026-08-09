use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel::<u32>();

    for id in 0..3u32 {
        let tx = tx.clone();
        thread::spawn(move || {
            // each producer sends one value; clones of tx are separate senders
            tx.send((id + 1) * 100).unwrap();
        });
    }
    drop(tx); // drop the original: now only the 3 clones remain

    let mut total = 0;
    let mut count = 0;
    for value in rx { // ends when ALL senders have dropped
        total += value;
        count += 1;
    }
    println!("count = {count}");
    println!("total = {total}");
}
