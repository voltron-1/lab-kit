// exhibit.rs — READ-ONLY EXHIBIT. Do NOT compile or run this; you are here to
// audit it. The // SAFETY comment below is a LIE. Find where it breaks.
use std::slice;

/// Reinterprets the first `len` bytes at `data` as a &[u8].
/// SAFETY: caller guarantees data points to len valid initialized bytes.
unsafe fn view(data: *const u8, len: usize) -> &'static [u8] {
    slice::from_raw_parts(data, len)
}

fn parse_record(buf: &[u8]) -> &[u8] {
    // read a big-endian length prefix, then hand back that many bytes
    let declared = u32::from_be_bytes([buf[0], buf[1], buf[2], buf[3]]) as usize;
    // BUG: `declared` comes from the buffer itself and is never checked
    // against buf.len(); from_raw_parts will read `declared` bytes starting
    // at buf[4] regardless of how long buf actually is.
    unsafe { view(buf[4..].as_ptr(), declared) }
}
