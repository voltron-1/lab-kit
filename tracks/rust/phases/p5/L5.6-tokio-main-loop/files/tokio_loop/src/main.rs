use tokio::task::JoinSet;
use tokio::time::{sleep, Duration};

async fn probe(port: u16) -> u16 {
    // pretend work: a short async wait, then "report" the port squared-ish
    sleep(Duration::from_millis((port % 5) as u64)).await;
    port
}

#[tokio::main]
async fn main() {
    let mut set = JoinSet::new();

    // the main loop: spawn one concurrent task per port
    for port in [22u16, 80, 443, 8080] {
        set.spawn(probe(port));
    }

    // drain: await tasks AS THEY COMPLETE (order not guaranteed)
    let mut sum: u32 = 0;
    let mut done = 0;
    while let Some(result) = set.join_next().await {
        sum += result.unwrap() as u32;
        done += 1;
    }

    println!("tasks completed = {done}");
    println!("port sum = {sum}");
}
