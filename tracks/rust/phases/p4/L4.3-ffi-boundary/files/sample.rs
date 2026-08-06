// The declaration below is a PROMISE: "somewhere there is a C function named
// abs taking one i32 and returning i32." Rust cannot check it. If the promise
// is wrong, the result is undefined behavior — no borrow checker reaches here.
extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    // SAFETY: abs is a real, pure libc function matching this signature.
    let a = unsafe { abs(-9) };
    println!("abs(-9) = {a}");

    let b = unsafe { abs(1024) };
    println!("abs(1024) = {b}");

    println!("the extern signature is unchecked — correctness is on the human");
}
