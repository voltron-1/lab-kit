// parse.rs — turns "field=count" args into a running total. It works on good
// input. Count the distinct ways a crafted argument can crash it.
fn main() {
    let mut total: u32 = 0;
    for arg in std::env::args().skip(1) {
        let (field, count) = arg.split_once('=').unwrap();      // A: no '='
        let n: u32 = count.parse().unwrap();                    // B: not a number
        let short = &field[..3];                                // C: <3 bytes / non-char-boundary
        total += n;                                             // D: overflow (debug panic)
        println!("{short}: {n}");
    }
    println!("total = {total}");
}
