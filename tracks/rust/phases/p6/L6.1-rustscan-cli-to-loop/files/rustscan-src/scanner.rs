// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: GPL-3.0-or-later
// PROVENANCE: https://github.com/RustScan/RustScan at commit c3a18e2 (retrieved 2026-08-06)

use std::net::SocketAddr;
use tokio::net::TcpStream;
use tokio::time::{timeout, Duration};

pub async fn scan_batch(batch: Vec<SocketAddr>, timeout_ms: u64) -> Vec<SocketAddr> {
    let mut open_ports = Vec::new();
    let mut futures = Vec::new();

    for addr in batch {
        futures.push(async move {
            let res = timeout(Duration::from_millis(timeout_ms), TcpStream::connect(addr)).await;
            match res {
                Ok(Ok(_stream)) => Some(addr),
                _ => None,
            }
        });
    }

    // Await batch of futures concurrently
    let results = futures::future::join_all(futures).await;
    for res in results {
        if let Some(addr) = res {
            open_ports.push(addr);
        }
    }
    open_ports
}
