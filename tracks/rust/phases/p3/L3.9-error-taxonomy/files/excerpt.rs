// excerpt.rs — READ-ONLY EXHIBIT (depends on thiserror/anyhow; not compiled
// here). Read it like a reviewer: two layers, two error styles.

// ---- library layer: feedparse/src/lib.rs ----
use thiserror::Error;

#[derive(Debug, Error)]
pub enum FeedError {
    #[error("malformed header at byte {0}")]
    BadHeader(usize),
    #[error("unsupported version {found} (max {max})")]
    Version { found: u8, max: u8 },
    #[error("io failure reading feed")]
    Io(#[from] std::io::Error),
}

pub fn parse_feed(raw: &[u8]) -> Result<Vec<Indicator>, FeedError> {
    // ... (body elided — the signatures are the lesson)
}

// ---- application layer: src/main.rs ----
use anyhow::{Context, Result};

fn run() -> Result<()> {
    let raw = std::fs::read("feed.bin").context("reading feed.bin")?;
    let indicators = parse_feed(&raw).context("parsing threat feed")?;
    println!("{} indicators", indicators.len());
    Ok(())
}
