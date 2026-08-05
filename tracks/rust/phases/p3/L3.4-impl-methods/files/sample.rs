struct Tally {
    hits: u32,
    label: String,
}

impl Tally {
    fn new(label: &str) -> Self {
        Tally { hits: 0, label: String::from(label) }
    }

    fn record(&mut self) {
        self.hits += 1;
    }

    fn report(&self) -> String {
        format!("{}: {} hits", self.label, self.hits)
    }

    fn into_label(self) -> String {
        self.label
    }
}

fn main() {
    let mut auth = Tally::new("failed-auth");
    auth.record();
    auth.record();
    auth.record();
    println!("{}", auth.report());

    let label = auth.into_label();
    println!("archived: {label}");

    // step 4 experiment: add another auth.report() call HERE, recompile,
    // read the error, then remove it again.
}
