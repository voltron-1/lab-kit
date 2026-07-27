triage order: error code -> the two spans (borrowed where, conflicted where) -> last use
E0382 moved-then-used · E0499 two writers · E0502 writer while a reader still lives
fixes are usually borrow-instead-of-move, or reorder so borrows don't overlap
