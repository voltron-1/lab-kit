// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: Apache-2.0
// PROVENANCE: https://github.com/vectordotdev/vector at commit 8d2e11a (retrieved 2026-08-06)

#[derive(Debug)]
pub enum DecodeError {
    InvalidJson,
    MalformedRecord,
}

pub struct JsonDecoder;

impl JsonDecoder {
    // Decoding is fallible and returns a Result. A malformed record returns Err, NEVER panics.
    pub fn decode(&self, bytes: &[u8]) -> Result<Option<String>, DecodeError> {
        if bytes.is_empty() {
            return Ok(None);
        }
        if bytes[0] != b'{' {
            return Err(DecodeError::InvalidJson);
        }
        Ok(Some(String::from_utf8_lossy(bytes).to_string()))
    }
}
