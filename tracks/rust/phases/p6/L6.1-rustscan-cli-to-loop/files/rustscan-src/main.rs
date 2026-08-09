// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: GPL-3.0-or-later
// PROVENANCE: https://github.com/RustScan/RustScan at commit c3a18e2 (retrieved 2026-08-06)

mod opts;
mod scanner;

use clap::Parser;
use opts::Opts;

#[tokio::main]
async fn main() {
    let opts = Opts::parse();
    println!("Scanning addresses {:?} with batch size {}", opts.addresses, opts.batch_size);
}
