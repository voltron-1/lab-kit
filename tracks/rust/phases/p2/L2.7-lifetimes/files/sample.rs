fn longer<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

struct Finding<'a> {
    rule: &'a str,
}

fn main() {
    let primary = String::from("credential-stuffing");
    let winner;
    {
        let secondary = String::from("port-sweep");
        winner = longer(&primary, &secondary);
        println!("winner = {winner}");
    }

    let finding = Finding { rule: &primary };
    println!("rule = {}", finding.rule);
}
