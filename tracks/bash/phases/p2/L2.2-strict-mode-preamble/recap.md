set -e: a failing command STOPS the script instead of letting it keep narrating success
set -u: an unset or typo'd variable is fatal and named, instead of silently expanding to nothing
set -o pipefail: a pipeline reports the first death, not just the last command's verdict
