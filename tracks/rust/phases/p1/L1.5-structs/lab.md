## BRIEF
Structs in Rust organize related data without constructor overhead or uninitialized fields:
- **Struct literals**: Create struct instances by initializing every field explicitly.
- **Field-init shorthand**: Writing `port,` is shorthand for `port: port` when a local variable matches the field name.
- **Struct update syntax (`..a`)**: Copies or moves remaining unlisted fields from instance `a`.

In this lab, you decode struct initialization patterns and field movement rules in `sample.rs`.

## GUIDED STEPS

1. **Read `sample.rs`**:
   Inspect `sample.rs`:
   ```rust
   #[derive(Debug)]
   struct Endpoint {
       host: String,
       port: u16,
       tls: bool,
   }

   fn make_local(port: u16) -> Endpoint {
       Endpoint {
           host: String::from("127.0.0.1"),
           port,
           tls: false,
       }
   }

   fn main() {
       let a = make_local(8080);
       println!("a = {a:?}");

       let b = Endpoint {
           host: String::from("10.0.0.5"),
           ..a
       };
       println!("b = {b:?}");
       println!("a.host = {}", a.host);
   }
   ```

2. **Compile and run `sample.rs`**:
   ```bash
   rustc sample.rs -o sample && ./sample
   ```
   Observe outputs for `a`, `b`, and `a.host`.

3. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `q1=b` (`port,` is field-init shorthand for `port: port`)
   - `q2=port,tls` (`..a` supplied `port` and `tls` in struct declaration order)
   - `q3=c` (`host` was explicitly overridden in `b`, so no non-`Copy` field was moved out of `a`)

4. **Verify your work**:
   ```bash
   lab check rust L1.5
   ```
