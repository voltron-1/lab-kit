read SC codes by class, not count: SC2115/SC2086/SC2035 are security-critical (rm -rf /, splitting, dash-filename-as-flag); SC2034/SC2006/SC2166 are cosmetic
ShellCheck-clean is necessary, not sufficient — it cannot see L3.7's injection construct, L3.5's arithmetic injection, or a missing set -euo pipefail (L2.8)
SC1090/SC1091 "can't follow source" is informational, not a defect — dynamic source paths are normal (our own harness uses a shellcheck source= directive)
