// READ-ONLY EXHIBIT. Audit it.
use std::net::TcpListener;
async fn serve(listener: TcpListener) {
    loop {
        let (conn, _) = listener.accept().unwrap(); // FLAW 1: unwrap in loop (CWE-248)
        tokio::spawn(async move {                  // FLAW 2: unbounded spawn (CWE-400)
            let _ = conn;
        });
    }
}
