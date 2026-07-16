rm -rf "$DIR/" with an empty DIR is rm -rf on the filesystem root — one unset variable away from wiping the machine (this class has caused real outages)
the fix is one token: "${DIR:?}" (or set -u) makes empty fatal, so the script dies instead of the filesystem
this is the footgun ShellCheck DOES catch — SC2115 — so a clean shellcheck run is part of the guardrail here
