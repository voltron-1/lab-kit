// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: MIT
// PROVENANCE: https://github.com/sharkdp/hexyl at commit a1b2c3d (retrieved 2026-08-06)

use std::io::Read;

pub fn format_hex<R: Read>(mut reader: R) {
    let mut buffer = [0u8; 16];
    while let Ok(bytes_read) = reader.read(&mut buffer) {
        if bytes_read == 0 {
            break;
        }
        for b in &buffer[..bytes_read] {
            print!("{:02x} ", b);
        }
        println!();
    }
}
