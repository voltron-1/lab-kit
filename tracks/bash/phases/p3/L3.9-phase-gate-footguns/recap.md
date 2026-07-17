one real deploy script carried six footguns at once: empty-var rm -rf (L3.2), $(cat) word-split (L3.1/L3.3), unquoted cp (L3.1), a bare rm *.tmp (L3.4), arithmetic injection (L3.5), a dynamically-built command dispatch (L3.7)
hardening is a fixed checklist: set -euo pipefail, ${VAR:?} on every path fed to rm, quote+-- every expansion, validate numerics, replace dynamic dispatch with a case allowlist
the proof is behavioral AND static: it runs safe under the fence (rm never escapes) and it's shellcheck-clean — necessary and sufficient only together with your own audit
