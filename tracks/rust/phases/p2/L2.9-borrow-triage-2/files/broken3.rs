fn main() {
    let newest;
    {
        let batch = String::from("evt-9911");
        newest = &batch;
    }
    println!("newest = {newest}");
}
