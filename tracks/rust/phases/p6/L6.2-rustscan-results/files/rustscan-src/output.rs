// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: GPL-3.0-or-later
// PROVENANCE: https://github.com/RustScan/RustScan at commit c3a18e2 (retrieved 2026-08-06)

use std::process::Command;

pub fn process_results(mut open_ports: Vec<u16>, target: &str) {
    // Sort open ports to ensure deterministic output
    open_ports.sort();
    open_ports.dedup();

    println!("Open ports: {:?}", open_ports);
    run_nmap(&open_ports, target);
}

pub fn run_nmap(ports: &[u16], target: &str) {
    let port_str = ports.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(",");
    
    // Subprocess execution: uses argument vector Command::new, avoiding shell string injection
    let status = Command::new("nmap")
        .arg("-sV")
        .arg("-p")
        .arg(&port_str)
        .arg(target)
        .status();

    match status {
        Ok(s) => println!("nmap exited with status {s}"),
        Err(e) => eprintln!("failed to execute nmap: {e}"),
    }
}
