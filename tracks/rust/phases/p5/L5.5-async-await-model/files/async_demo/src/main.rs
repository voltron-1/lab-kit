use tokio::time::{sleep, Duration};

async fn work(id: u32) -> u32 {
    // an async fn body does NOT run when called — only when the returned
    // Future is awaited. This sleep yields control back to the runtime.
    sleep(Duration::from_millis(10)).await;
    id * 2
}

// current_thread flavor: one thread, so join! below is concurrency (interleaving
// awaits), never parallelism — exactly the mental model this lab teaches.
#[tokio::main(flavor = "current_thread")]
async fn main() {
    let fut = work(21);                 // nothing has run yet — fut is inert
    println!("future created, not yet awaited");

    let result = fut.await;             // NOW work(21) actually runs
    println!("result = {result}");

    // join! drives two futures concurrently on this one thread
    let (a, b) = tokio::join!(work(1), work(2));
    println!("a = {a}, b = {b}");
}
