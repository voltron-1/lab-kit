as never fails — it truncates or extends silently; there is no error path
a narrowing as before a bounds check defeats the check: 65636 as u16 is 100 <= 4096
CWE-197: any as on input-derived sizes/indices is a flag; TryFrom makes overflow a decision
