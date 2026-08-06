use std::convert::TryFrom;

// A gatekeeper that rejects oversized records... or does it?
fn accept(declared_len: u32) -> bool {
    const MAX: u16 = 4096;
    // BUG: declared_len is truncated to u16 BEFORE the comparison. A value
    // whose low 16 bits are small sails through, no matter how large it is.
    let checked = declared_len as u16;
    checked <= MAX
}

fn main() {
    let honest: u32 = 512;
    println!("accept(512) = {}", accept(honest));

    // 65536 + 100 = 0x10064; as u16 -> 0x0064 = 100, which is <= 4096.
    let hostile: u32 = 65_636;
    println!("accept(65636) = {}", accept(hostile));
    println!("truncated view of 65636 = {}", hostile as u16);

    // The safe gate: TryFrom refuses to narrow a value that does not fit.
    let safe_gate = u16::try_from(hostile).map(|v| v <= 4096).unwrap_or(false);
    println!("safe gate accepts 65636 = {safe_gate}");
}
