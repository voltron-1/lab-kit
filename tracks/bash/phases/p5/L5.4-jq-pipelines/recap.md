jq filters transform one JSON value into another; -c prints each result compact (one line), the natural shape for streaming NDJSON logs.
Object-construction keys are just strings — "source.ip" is one literal key with a dot in its name, which is exactly how flat schemas like ECS represent what looks like nesting.
jq has real control flow (if/then/else, functions like test()) usable inline inside a filter — a reshape pipeline is a small program, not just field selection.
