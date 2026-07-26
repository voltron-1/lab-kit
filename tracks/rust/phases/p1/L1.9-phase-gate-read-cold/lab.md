## BRIEF
Congratulations on reaching the **Phase 1 Gate**!
In this lab, you test your Rust reading literacy by analyzing a 60-line triage tool (`triage.rs`) cold.

The program combines all Phase 1 concepts:
- Structs and Enums (`#[derive(Debug)]`)
- `Option<T>` returns and `unwrap_or`
- Block expressions, `if` returns, and integer division
- Borrowing (`&Source`) vs move semantics
- Integer overflow traps (CWE-190)

> [!IMPORTANT]
> Honor the gate contract: read `triage.rs` and record your 10 answers in `answers.txt` **BEFORE** compiling and executing `triage.rs`.

## GUIDED STEPS

1. **Read `triage.rs` cold**:
   Inspect `triage.rs`:
   ```rust
   #[derive(Debug)]
   enum Verdict {
       Benign,
       Suspicious,
       Hostile,
   }

   struct Source {
       name: String,
       failures: u8,
       internal: bool,
   }

   fn service_port(service: &str) -> Option<u16> {
       match service {
           "ssh" => Some(22),
           "rdp" => Some(3389),
           _ => None,
       }
   }

   fn judge(source: &Source) -> Verdict {
       let score = {
           let base = if source.internal { 0 } else { 2 };
           base + source.failures / 3
       };
       if score == 0 {
           Verdict::Benign
       } else if score < 4 {
           Verdict::Suspicious
       } else {
           Verdict::Hostile
       }
   }

   fn main() {
       let sources = [
           Source { name: String::from("build-server"), failures: 2, internal: true },
           Source { name: String::from("laptop-7"), failures: 9, internal: true },
           Source { name: String::from("203.0.113.9"), failures: 7, internal: false },
       ];

       let mut hostile_count = 0;
       let mut total: u8 = 0;
       for source in &sources {
           let verdict = judge(source);
           println!("{} -> {:?}", source.name, verdict);
           if let Verdict::Hostile = verdict {
               hostile_count += 1;
           }
           total += source.failures;
       }
       println!("hostile: {hostile_count}");
       println!("total failures: {total}");

       let target = service_port("rdp").unwrap_or(0);
       println!("watch port {target}");
   }
   ```

2. **Record your answers in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in all 10 fields:
   - `q1=Benign` (base 0 + 2/3=0 → score 0)
   - `q2=Suspicious` (base 0 + 9/3=3 → score 3)
   - `q3=Hostile` (base 2 + 7/3=2 → score 4)
   - `q4=1` (1 hostile verdict: 203.0.113.9)
   - `q5=18` (total failures: 2 + 9 + 7 = 18)
   - `q6=3389` (watch port for rdp)
   - `q7=3` (for internal=false, failures=5: base 2 + 5/3=1 → score 3)
   - `q8=b` (`judge` takes `&Source` borrow)
   - `q9=b` (`service_port("http")` returns `None`)
   - `q10=b` (`total: u8` accumulator risks CWE-190 overflow)

3. **Compile and execute `triage.rs`**:
   ```bash
   rustc triage.rs -o triage && ./triage
   ```
   Compare program outputs with your answers.

4. **Verify your work**:
   ```bash
   lab check rust L1.9
   ```
