// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: MIT
// PROVENANCE: https://github.com/sharkdp/hexyl at commit a1b2c3d (retrieved 2026-08-06)

mod hex;

use std::env;
use std::fs::File;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: hexyl <file>");
        return;
    }
    let file = File::open(&args[1]).expect("Failed to open file");
    hex::format_hex(file);
}
