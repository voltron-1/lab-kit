use std::rc::Rc;
use std::thread;

fn main() {
    let counter = Rc::new(5);
    let clone = Rc::clone(&counter);
    thread::spawn(move || {
        println!("{}", clone); // Rc is !Send — cannot cross the boundary
    });
}
