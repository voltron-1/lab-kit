# shellcheck shell=bash
# lib/hints.sh — graduated hint ladder. Print-then-bump: the hint level is
# only persisted AFTER it has been printed, so a SIGINT between print and
# write can at worst cost the kit a re-shown hint, never cost the learner a
# paid-but-unseen one.

hint_next() {
  local track="$1" id="$2" lab_dir="$3" rec used total hint remaining
  rec="$(state_lab_json "$track" "$id")"
  used="$(jq -r '.hints_used' <<< "$rec")"
  total="$(jq '.hints | length' "$lab_dir/hints.json")"
  if [[ "$used" -ge "$total" ]]; then
    printf 'no more hints for %s %s — all %s shown.\n' "$track" "$id" "$total"
    printf 'run: lab check %s %s when ready.\n' "$track" "$id"
    return 0
  fi
  hint="$(jq -r --argjson i "$used" '.hints[$i]' "$lab_dir/hints.json")"
  printf '\n[hint %d/%d] %s %s\n' "$((used + 1))" "$total" "$track" "$id"
  printf '  %s\n' "$hint"
  remaining=$((total - used - 1))
  if [[ "$remaining" -gt 0 ]]; then
    printf '\n(%d hints remaining — run lab hint %s %s again for the next)\n' "$remaining" "$track" "$id"
  else
    printf '\n(that was the last hint)\n'
  fi
  state_record_hint "$track" "$id" "$total"
}
