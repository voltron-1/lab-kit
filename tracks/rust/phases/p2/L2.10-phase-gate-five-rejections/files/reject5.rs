fn main() {
    let survivor;
    {
        let tmp = String::from("short-lived");
        survivor = &tmp;
    }
    println!("{survivor}");
}
