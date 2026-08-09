# URL Analysis Legend
- Redirect chains must be followed to the final landing domain.
- Homoglyph/digit lookalikes swap letters (e.g. `i` -> `1`).
- Punycode (`xn--`) encodes internationalized Unicode domains in ASCII.
- Always defang URLs (`hxxp://`, `[.]`).
