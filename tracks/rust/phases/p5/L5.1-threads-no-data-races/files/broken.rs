use std::thread;

fn main() {
    let mut log = vec![String::from("start")];
    thread::spawn(|| {
        log.push(String::from("from thread"));
    });
    log.push(String::from("from main"));
    println!("{log:?}");
}
