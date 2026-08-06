fn main() {
    // Superpower #1: dereference a raw pointer.
    let value = 42u32;
    let ptr: *const u32 = &value;
    // SAFETY: ptr was just made from a live &value on this stack frame; it is
    // non-null, aligned, and initialized, and value outlives this block.
    let read = unsafe { *ptr };
    println!("read = {read}");

    // Superpower #2: call an unsafe function. get_unchecked skips bounds checks.
    let bytes = [10u8, 20, 30, 40];
    let index = 2;
    // SAFETY: index (2) is < bytes.len() (4), checked on the line above.
    let byte = unsafe { *bytes.get_unchecked(index) };
    println!("byte = {byte}");

    println!("unsafe did NOT disable the borrow checker or the type system");
}
