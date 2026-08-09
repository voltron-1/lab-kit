// server.rs — READ-ONLY EXHIBIT (tokio-shaped; not compiled here). Audit this
// accept loop for async DoS patterns. It is memory-safe. It is not safe.
use tokio::net::TcpListener;

async fn handle(mut conn: tokio::net::TcpStream) {
    let mut buf = vec![0u8; 1024];
    // FLAW 1 (CWE-400): read with NO timeout. A client that connects and never
    // sends holds this task open forever (slowloris) — an unbounded await.
    let _ = conn_read(&mut conn, &mut buf).await;
    // ... process ...
}

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("0.0.0.0:9000").await.unwrap();
    loop {
        let (conn, _addr) = listener.accept().await.unwrap();
        // FLAW 2 (CWE-400): spawn per connection with NO concurrency cap. A flood
        // of connections spawns unbounded tasks — memory/FD exhaustion.
        tokio::spawn(handle(conn));
    }
}

// (conn_read is a stand-in for an awaited read with no time bound)
async fn conn_read(_c: &mut tokio::net::TcpStream, _b: &mut [u8]) -> usize { 0 }
