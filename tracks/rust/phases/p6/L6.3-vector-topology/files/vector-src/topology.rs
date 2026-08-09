// READ-ONLY EXHIBIT — never compiled or run; you are here to read
// SPDX-License-Identifier: Apache-2.0
// PROVENANCE: https://github.com/vectordotdev/vector at commit 8d2e11a (retrieved 2026-08-06)

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Event {
    pub fields: HashMap<String, String>,
}

pub trait Source {
    fn name(&self) -> &str;
}

pub trait Transform {
    fn transform(&self, event: Event) -> Vec<Event>; // zero, one, or many events
}

pub trait Sink {
    fn emit(&self, events: Vec<Event>);
}
