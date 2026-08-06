memory safety is not availability — every panic on an input path is a DoS (CWE-248)
panics are more than unwrap: indexing, slicing, overflow (debug), and / 0 all crash
audit by reachability; fix per site — handle None, use ?, .get(..), checked_add
