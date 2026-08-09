// scanner.rs — READ-ONLY EXHIBIT. Trace the DATA FLOW; do not compile or run.
// A bounded-concurrency TCP port scanner: the standard tokio architecture.
use std::sync::Arc;
use tokio::net::TcpStream;
use tokio::sync::{mpsc, Semaphore};
use tokio::time::{timeout, Duration};

const MAX_IN_FLIGHT: usize = 100;   // concurrency cap
const CONNECT_TIMEOUT: Duration = Duration::from_millis(500);

async fn probe(host: String, port: u16) -> Option<u16> {
    // bounded await: a connect that cannot hang longer than CONNECT_TIMEOUT
    match timeout(CONNECT_TIMEOUT, TcpStream::connect((host, port))).await {
        Ok(Ok(_stream)) => Some(port),   // connected -> port is open
        _ => None,                       // timed out or refused -> closed
    }
}

#[tokio::main]
async fn main() {
    let host = String::from("scanme.example.test");
    // the permit pool: at most MAX_IN_FLIGHT probes run at once
    let limiter = Arc::new(Semaphore::new(MAX_IN_FLIGHT));
    let (tx, mut rx) = mpsc::channel::<u16>(MAX_IN_FLIGHT);

    // producer: spawn one bounded task per port
    for port in 1u16..=1024 {
        let permit = Arc::clone(&limiter).acquire_owned().await.unwrap();
        let tx = tx.clone();
        let host = host.clone();
        tokio::spawn(async move {
            if let Some(open) = probe(host, port).await {
                let _ = tx.send(open).await;   // report open ports over the channel
            }
            drop(permit);                      // release the slot on finish
        });
    }
    drop(tx); // drop the original sender so the collector loop can end

    // consumer: collect open ports until every sender has dropped
    let mut open_ports: Vec<u16> = Vec::new();
    while let Some(port) = rx.recv().await {
        open_ports.push(port);
    }
    open_ports.sort();   // completion order is nondeterministic — sort to stabilize
    println!("open ports: {open_ports:?}");
}
