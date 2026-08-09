// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: MIT OR Apache-2.0
// PROVENANCE: https://github.com/rusticata/tls-parser at commit 4f1a90c (retrieved 2026-08-06)

#[derive(Debug, PartialEq)]
pub struct Record {
    pub tag: u8,
    pub payload: Vec<u8>,
}

// Simulated nom IResult type: IResult<&[u8], Record>
pub type IResult<I, O> = Result<(I, O), &'static str>;

pub fn take(count: usize) -> impl Fn(&[u8]) -> IResult<&[u8], &[u8]> {
    move |i: &[u8]| {
        if i.len() < count {
            Err("Incomplete") // Bounds-checked: returns Err on short input, NEVER out-of-bounds read
        } else {
            Ok((&i[count..], &i[..count]))
        }
    }
}

pub fn parse_record(input: &[u8]) -> IResult<&[u8], Record> {
    if input.is_empty() {
        return Err("Incomplete");
    }
    let tag = input[0];
    let (remaining, payload_bytes) = take(4)(&input[1..])?;
    Ok((remaining, Record { tag, payload: payload_bytes.to_vec() }))
}
