//! Parsing helpers for the scanport CLI.

/// Parse a decimal port string. Returns `None` unless it is 1..=65535.
pub fn parse_port(raw: &str) -> Option<u16> {
    match raw.trim().parse::<u16>() {
        Ok(0) => None,
        Ok(port) => Some(port),
        Err(_) => None,
    }
}

#[cfg(test)]
mod tests {
    use super::parse_port;

    #[test]
    fn rejects_zero() {
        assert_eq!(parse_port("0"), None);
    }
}
