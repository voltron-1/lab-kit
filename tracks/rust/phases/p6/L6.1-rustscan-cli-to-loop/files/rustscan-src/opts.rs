// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: GPL-3.0-or-later
// PROVENANCE: https://github.com/RustScan/RustScan at commit c3a18e2 (retrieved 2026-08-06)

use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about)]
pub struct Opts {
    /// Target IP addresses or hostnames to scan
    #[arg(short, long)]
    pub addresses: Vec<String>,

    /// Specific ports to scan (e.g. 80,443)
    #[arg(short, long)]
    pub ports: Option<String>,

    /// Batch size for socket connections (concurrency bound)
    #[arg(short, long, default_value_t = 4500)]
    pub batch_size: u16,

    /// Timeout in milliseconds for each port connection
    #[arg(short, long, default_value_t = 1500)]
    pub timeout: u64,
}
