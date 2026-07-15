case races GLOB patterns (not regex) top-to-bottom against one word — FIRST match wins, order is priority
;; ends an arm with no fallthrough; pat1|pat2 is alternation; *) is the catch-all default
no matching arm and no *) means case does nothing and exits 0 — a silent non-decision
