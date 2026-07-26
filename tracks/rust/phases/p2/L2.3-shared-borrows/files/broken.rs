fn main() {
    let config = String::from("mode=passive");
    let view = &config;
    view.push_str(";debug=1");
    println!("{view}");
}
