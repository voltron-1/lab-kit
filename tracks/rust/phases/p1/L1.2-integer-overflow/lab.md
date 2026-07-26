## BRIEF
Integer overflow in Rust behaves differently depending on the build profile:
- **Debug profile** (`cargo run`): Overflow checks are enabled; integer overflow results in a runtime **panic**.
- **Release profile** (`cargo run --release`): Overflow checks are disabled by default; integer overflow performs **two's complement wrapping**.

To write unambiguous code, Rust provides explicit methods: `checked_add()`, `wrapping_add()`, and `saturating_add()`.

In this lab, you predict how `u8::MAX + 1` behaves in debug vs release profiles, observing security implications related to Integer Overflow (CWE-190).

## GUIDED STEPS

1. **Read `overflow/src/main.rs`**:
   Inspect `overflow/src/main.rs`:
   ```rust
   fn bump(n: u8) -> u8 {
       n + 1
   }

   fn main() {
       let max: u8 = u8::MAX;
       println!("max = {max}");
       println!("checked = {:?}", max.checked_add(1));
       println!("wrapped = {}", max.wrapping_add(1));
       println!("bumped = {}", bump(max));
   }
   ```

2. **Record your predictions**:
   Copy `predictions.template.txt` to `predictions.txt`:
   ```bash
   cp predictions.template.txt predictions.txt
   ```
   Set:
   - `debug=panic` (debug profile panics on overflow)
   - `release=0` (`u8::MAX + 1` wraps to `0` in release)
   - `checked=None` (`checked_add(1)` returns `None`)
   - `wrapped=0` (`wrapping_add(1)` returns `0`)

3. **Run under the Debug profile**:
   Change into `overflow`, run debug mode capturing stdout and stderr, then return:
   ```bash
   cd overflow && cargo run > ../debug_out.txt 2>&1 || true && cd ..
   ```
   Verify `debug_out.txt` contains the panic message `attempt to add with overflow`.

4. **Run under the Release profile**:
   Run in release mode:
   ```bash
   cd overflow && cargo run --release > ../release_out.txt 2>&1 && cd ..
   ```
   Verify `release_out.txt` contains `bumped = 0`.

5. **Verify your work**:
   ```bash
   lab check rust L1.2
   ```
