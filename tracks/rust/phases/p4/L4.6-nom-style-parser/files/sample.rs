// A nom-style parser reads a byte stream by consuming pieces and returning the
// value plus the REMAINING input. Real nom returns IResult; this hand-rolled
// version uses Option to keep the shape without a dependency. The security
// lesson is identical: every read is bounds-checked before it happens.

/// Take exactly `n` bytes; return (taken, rest) or None if not enough input.
fn take(input: &[u8], n: usize) -> Option<(&[u8], &[u8])> {
    if input.len() < n {
        return None; // the whole game: refuse before reading past the end
    }
    Some((&input[..n], &input[n..]))
}

/// Parse: [1-byte tag][1-byte length N][N bytes payload].
fn parse_record(input: &[u8]) -> Option<(u8, &[u8], &[u8])> {
    let (tag, rest) = take(input, 1)?;
    let (len_byte, rest) = take(rest, 1)?;
    let declared = len_byte[0] as usize;
    let (payload, rest) = take(rest, declared)?; // declared is CHECKED by take
    Some((tag[0], payload, rest))
}

fn main() {
    // tag=0x01, len=3, payload="abc", then a trailing 0xFF
    let good = [0x01u8, 0x03, b'a', b'b', b'c', 0xFF];
    match parse_record(&good) {
        Some((tag, payload, rest)) => {
            println!("tag = {tag}");
            println!("payload len = {}", payload.len());
            println!("trailing bytes = {}", rest.len());
        }
        None => println!("truncated"),
    }

    // A hostile record: claims length 200 but only 2 payload bytes follow.
    let hostile = [0x01u8, 0xC8, b'a', b'b'];
    match parse_record(&hostile) {
        Some(_) => println!("parsed (unexpected)"),
        None => println!("rejected: declared length exceeds input"),
    }
}
