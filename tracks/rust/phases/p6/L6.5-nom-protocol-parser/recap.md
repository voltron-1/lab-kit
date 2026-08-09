a real nom parser threads IResult<&[u8], T> through tag/take/be_u16/map — L4.6 in production
take(n) is bounds-checked: a hostile length is a parse error, never an out-of-bounds read
combinator libraries make "refuse before reading past the end" structural — why parsers use nom
