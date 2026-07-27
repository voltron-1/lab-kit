fn main() {
    let mut queue = String::from("alert-1");
    let snapshot = &queue;
    queue.push_str(",alert-2");
    println!("snapshot = {snapshot}");
    println!("queue = {queue}");
}
