Untrusted search path (CWE-426): if PATH holds . or any attacker-writable directory, a bare command name (ps, pgrep, anything) can resolve to the attacker's file — with root's privilege, if the script runs privileged
fix by pinning an absolute, minimal PATH before any command lookup happens — reassigning PATH inside the script wins regardless of what the caller passed in; never trust the inherited environment
IFS is the sibling footgun: a hostile inherited IFS changes splitting (L3.3) the same way a hostile PATH changes command resolution — reset what you depend on, don't inherit it
