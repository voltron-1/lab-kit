#!/usr/bin/env bash
# tools/lint-labs.sh — compensating control for the sandbox fence: there is
# no OS boundary against a check.sh that hardcodes an absolute path, so
# this lint bans the patterns that would let one slip past review, plus
# structural checks on every lab's content files. Run before every commit
# that touches tracks/**.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"

fail_count=0

lint_fail() {
  printf 'lint-labs: %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

# check.sh is ALWAYS executed by `lab check` — never a "teaching sample" a
# learner merely reads — so it gets no exemptions of any kind. (Deliberately
# broken teaching samples, per the curriculum maps, live under a lab's
# files/ directory, which this lint never scans and shellcheck-all.sh never
# sweeps — they need no exemption because they were never in scope.)
# allow_file entries are "<path>:<line> — <reason>"; match the <path>:<line>
# prefix EXACTLY (up to the first space), never as a substring — "foo.sh:1"
# must not match an entry for "foo.sh:10" or "otherfoo.sh:1".
_lint_allow_has_entry() {
  local f="$1" lineno="$2" allow_file="$3" line entry
  [[ -f "$allow_file" ]] || return 1
  while IFS= read -r line; do
    entry="${line%% *}"
    [[ "$entry" == "$f:$lineno" ]] && return 0
  done < "$allow_file"
  return 1
}

check_absolute_paths() {
  local f="$1" allow_file="$ROOT/tools/lint-allow.txt" lineno content
  # Two structural, harmless exemptions (every other line is real code and
  # gets no free pass):
  #   - line 1, the shebang (e.g. "#!/usr/bin/env bash")
  #   - a full-line "# shellcheck ..." directive (e.g. the mandatory
  #     "# shellcheck source=/dev/null" every check.sh carries, since
  #     $LAB_CHECKLIB is a dynamic path) — these are pure static-analysis
  #     hints for the shellcheck TOOL, never executed by bash or the
  #     harness, so a path-shaped directive value has no runtime effect
  #     and needs no per-file lint-allow.txt entry.
  while IFS=: read -r lineno content; do
    [[ -z "$lineno" ]] && continue
    [[ "$lineno" == "1" ]] && continue
    if [[ "$content" =~ ^[[:space:]]*#[[:space:]]*shellcheck[[:space:]] ]]; then
      continue
    fi
    if [[ "$content" == *"# lint-allow:"* ]]; then
      if _lint_allow_has_entry "$f" "$lineno" "$allow_file"; then
        continue
      fi
      lint_fail "$f:$lineno: '# lint-allow:' comment has no matching entry in tools/lint-allow.txt"
      continue
    fi
    lint_fail "$f:$lineno: absolute-path literal found (escape hatch: trailing '# lint-allow: <reason>' + a matching '<path>:<line>' entry in tools/lint-allow.txt)"
  done < <(grep -nE '(^|[^[:alnum:]_./-])/([[:alnum:]_./*-]*)?([[:space:]"'"'"')]|$)' "$f")
}

check_check_sh() {
  local f="$1"
  grep -q '^set -euo pipefail$' "$f" || lint_fail "$f: missing 'set -euo pipefail' preamble"
  grep -q ": \"\${LAB_WORKSPACE:?" "$f" || lint_fail "$f: missing LAB_WORKSPACE guard"
  grep -q ": \"\${LAB_CHECKLIB:?" "$f" || lint_fail "$f: missing LAB_CHECKLIB guard"
  grep -q "source \"\$LAB_CHECKLIB\"" "$f" || lint_fail "$f: does not source \$LAB_CHECKLIB"

  local mode
  mode="$(stat -c '%a' "$f")"
  [[ "$mode" == "644" ]] || lint_fail "$f: mode is $mode, expected 644 (not executable — must be launched via 'bash --')"

  check_absolute_paths "$f"

  # Word-boundary matching, not substring: -F/plain substring would flag
  # "evaluate"/"retrieval" for 'eval' and "pushdown" for 'pushd' (false
  # positives), while a hand-padded ' nc ' still misses "nc" at the very
  # start of a line (false negative). -w fixes both directions. Case-
  # sensitive: these are bash/POSIX tokens, not case-insensitive-language
  # aliases, so -i would risk new false positives (e.g. a stray "Eval" in
  # prose) for no benefit here.
  local token
  for token in 'eval' 'sudo' 'curl' 'wget' 'nc' 'ssh' 'sh -c' 'bash -c' 'pushd' 'bin/lab'; do
    if grep -qw -- "$token" "$f"; then
      lint_fail "$f: banned token '$token'"
    fi
  done
  # Attack-content ceiling (ps-p4+): PowerShell is case-insensitive, so
  # these MUST be -i (a bare 'iex' ban misses 'IEX', the alias everyone
  # actually types — verified against this exact gap in an earlier draft).
  # grep/assert against learner text is fine; route a literal around this
  # scan by building it from concatenated string pieces (same workaround
  # already established for the eval ban above), never with a bare
  # '# lint-allow' exemption — these tokens get no exemption of any kind.
  for token in 'iex' 'Invoke-Expression' 'DownloadString' 'Invoke-WebRequest' \
    'Start-BitsTransfer' 'EncodedCommand' 'certutil' 'mshta' 'rundll32' 'regsvr32' \
    'iwr' 'irm' 'Invoke-RestMethod' 'DownloadFile' 'DownloadData' 'bitsadmin'; do
    if grep -qwi -- "$token" "$f"; then
      lint_fail "$f: banned attack-content token '$token' (case-insensitive — check.sh must never execute an attacker primitive)"
    fi
  done
  # The invariant that actually matters isn't the primitive's name (PS has
  # aliases and unambiguous-prefix flag matching, so a name list is always
  # incomplete) but the SHAPE: pwsh/powershell invoked with an inline-code
  # flag (-Command/-c/-EncodedCommand/-e/-enc, any unambiguous abbreviation)
  # rather than -File against a shipped, reviewed .ps1 — the only pattern
  # every benign probe in this repo uses. Verified zero false positives
  # against the current repo before adding this.
  if grep -qEi -- '(pwsh|powershell)([[:space:]]+-[A-Za-z]+)*[[:space:]]+-(c|com|comm|command|e|ec|enc|encodedcommand)\b' "$f"; then
    lint_fail "$f: banned pattern: pwsh/powershell invoked with an inline-code flag (-Command/-EncodedCommand or an abbreviation) — ship a reviewed .ps1 and invoke it via -File instead"
  fi
  # cd .. / cd ~ are relative escapes with no leading '/', so the absolute-
  # path check above can't see them; quoting (cd ".." / cd '~') doesn't
  # change what they do, so this matches regardless of quote style.
  if grep -qE 'cd[[:space:]]+["'"'"']?(\.\.|~)' "$f"; then
    lint_fail "$f: banned pattern: cd into .. or ~ (escapes the workspace fence)"
  fi
}

check_quiz_json() {
  local f="$1" n i b64
  jq -e '.questions | length == 3' "$f" > /dev/null 2>&1 \
    || lint_fail "$f: quiz.json must have exactly 3 questions"
  n="$(jq '.questions | length' "$f" 2> /dev/null || echo 0)"
  for ((i = 0; i < n; i++)); do
    if ! jq -e --argjson i "$i" '.questions[$i].answer_b64' "$f" > /dev/null 2>&1; then
      lint_fail "$f: question $i missing answer_b64"
      continue
    fi
    b64="$(jq -r --argjson i "$i" '.questions[$i].answer_b64' "$f")"
    printf '%s' "$b64" | base64 -d > /dev/null 2>&1 \
      || lint_fail "$f: question $i answer_b64 does not decode"
  done
}

check_hints_json() {
  local f="$1"
  jq -e '.hints | length == 3' "$f" > /dev/null 2>&1 \
    || lint_fail "$f: hints.json must have exactly 3 levels"
}

check_meta_json() {
  local f="$1"
  jq -e '.id and .title and .type and (.gate | type == "boolean") and .est_minutes' "$f" > /dev/null 2>&1 \
    || lint_fail "$f: meta.json missing a required field"
}

# The ps track's curriculum (docs/plans/ps-p4-plan.md §2c) mandates every IOC
# be defanged (hxxp/hxxps, bracketed dots) and fictional. Scoped to tracks/ps
# only: the bash and soc tracks have their own, deliberately DIFFERENT
# convention (realistic-looking undefanged URLs against RFC-reserved/.test
# domains — see tracks/bash/phases/p4/L4.2-curl-bash-audit/files/install.sh
# and PROMPTS.md's soc rule that raw evidence must NOT be defanged), so this
# check must never run repo-wide.
check_ps_files_defanged() {
  local f lineno content
  while IFS= read -r -d '' f; do
    while IFS=: read -r lineno content; do
      [[ -z "$lineno" ]] && continue
      lint_fail "$f:$lineno: undefanged URL scheme — ps track requires hxxp/hxxps, not http/https"
    done < <(grep -InEI 'https?://' "$f" 2> /dev/null)
  done < <(find tracks/ps -type f -print0 2> /dev/null)
}

any=0
while IFS= read -r -d '' dir; do
  any=1
  check_check_sh "$dir/check.sh"
  check_quiz_json "$dir/quiz.json"
  check_hints_json "$dir/hints.json"
  check_meta_json "$dir/meta.json"
done < <(find tracks -mindepth 4 -maxdepth 4 -type d -name 'L*.*-*' -print0 2> /dev/null)

if [[ "$any" == "0" ]]; then
  echo "lint-labs: no lab directories found under tracks/" >&2
fi

check_ps_files_defanged

echo "--- shellcheck sweep ---"
if ! "$ROOT/tools/shellcheck-all.sh"; then
  lint_fail "shellcheck sweep reported warnings (see above)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'lint-labs: %d problem(s) found\n' "$fail_count" >&2
  exit 1
fi
echo "lint-labs: clean"
