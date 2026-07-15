functions are commands: return sends a ONE-BYTE verdict to if/&&/|| — 300 wraps to 44, it can't carry data
echo sends text to $( ) capture — out=$(fn) stays EMPTY if fn only returns; never confuse the channels
local fences a function's variables; without it every assignment silently edits the caller's world
