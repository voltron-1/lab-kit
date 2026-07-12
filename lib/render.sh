# shellcheck shell=bash
# lib/render.sh — every terminal output format: status board, start brief,
# recap card, resume card. Marks are semantic (✓ ▶ ○ ⏭), not decorative,
# and layout/wording never changes between a tty and a pipe.

readonly MARK_PASS="✓"
readonly MARK_PROGRESS="▶"
readonly MARK_TODO="○"
readonly MARK_SKIPPED="⏭"
readonly MARK_FAIL="✗"

_glyph_for() {
  local status="$1" skipped="$2"
  if [[ "$skipped" == "true" ]]; then
    printf '%s' "$MARK_SKIPPED"
  elif [[ "$status" == "passed" ]]; then
    printf '%s' "$MARK_PASS"
  elif [[ "$status" == "in_progress" ]]; then
    printf '%s' "$MARK_PROGRESS"
  else
    printf '%s' "$MARK_TODO"
  fi
}

render_status() {
  printf '%sLAB-KIT%s — status\n' "$C_BOLD" "$C_RST"
  printf '══════════════════════════════════════════════════════════\n'
  local track any=0
  for track in $(catalog_tracks); do
    any=1
    printf '\n'
    render_status_track "$track"
  done
  [[ "$any" == "0" ]] && printf '\nno tracks installed yet.\n'
  printf '\n--------------------------------------------------------------\n'
  printf '%s passed   %s in progress   %s not done   %s forced (--force, never %s)\n' \
    "$MARK_PASS" "$MARK_PROGRESS" "$MARK_TODO" "$MARK_SKIPPED" "$MARK_PASS"
  render_next_footer
}

render_status_track() {
  local track="$1" title labs_tsv
  title="$(catalog_track_title "$track")"
  labs_tsv="$(catalog_labs "$track")"
  if [[ -z "$labs_tsv" ]]; then
    printf '%s   no labs installed yet\n' "$track"
    return 0
  fi

  local total=0 passed=0 skipped=0
  local phase _ id dir rec status sk
  while IFS=$'\t' read -r phase _ id dir; do
    [[ -z "$id" ]] && continue
    total=$((total + 1))
    rec="$(state_lab_json "$track" "$id")"
    status="$(jq -r '.status' <<< "$rec")"
    sk="$(jq -r '.skipped' <<< "$rec")"
    [[ "$status" == "passed" ]] && passed=$((passed + 1))
    [[ "$sk" == "true" ]] && skipped=$((skipped + 1))
  done <<< "$labs_tsv"

  printf '%s · %s   %s %s · %s %s · %s %s  (%s/%s)\n' \
    "$track" "$title" "$passed" "$MARK_PASS" "$skipped" "$MARK_SKIPPED" \
    "$((total - passed - skipped))" "$MARK_TODO" "$passed" "$total"

  local cur_phase="" phase_title title_lab gate est mark gate_tag
  while IFS=$'\t' read -r phase _ id dir; do
    [[ -z "$id" ]] && continue
    if [[ "p$phase" != "$cur_phase" ]]; then
      cur_phase="p$phase"
      phase_title="$(catalog_phase_title "$track" "$cur_phase")"
      if [[ -n "$phase_title" ]]; then
        printf '  %s · %s\n' "$cur_phase" "$phase_title"
      else
        printf '  %s\n' "$cur_phase"
      fi
    fi
    rec="$(state_lab_json "$track" "$id")"
    status="$(jq -r '.status' <<< "$rec")"
    sk="$(jq -r '.skipped' <<< "$rec")"
    mark="$(_glyph_for "$status" "$sk")"
    title_lab="$(jq -r '.title' "$dir/meta.json")"
    gate="$(jq -r '.gate' "$dir/meta.json")"
    est="$(jq -r '.est_minutes' "$dir/meta.json")"
    gate_tag=""
    [[ "$gate" == "true" ]] && gate_tag="GATE"
    printf '    %s  %-6s %-42s %-4s ~%sm\n' "$mark" "$id" "$title_lab" "$gate_tag" "$est"
  done <<< "$labs_tsv"
}

render_next_footer() {
  local track id title
  for track in $(catalog_tracks); do
    id="$(catalog_frontier "$track")"
    if [[ -n "$id" ]]; then
      title="$(catalog_meta "$track" "$id" "title")"
      printf 'next: %s %s — %s   run: lab start %s %s\n' "$track" "$id" "$title" "$track" "$id"
      return 0
    fi
  done
  printf 'next: nothing unlocked — every installed track is complete\n'
}

_extract_brief() {
  awk '/^## BRIEF$/{flag=1; next} /^## GUIDED STEPS$/{flag=0} flag' "$1"
}

render_brief() {
  local track="$1" id="$2" dir title type gate est objective ws_path tag
  dir="$(catalog_lab_dir "$track" "$id")"
  title="$(jq -r '.title' "$dir/meta.json")"
  type="$(jq -r '.type' "$dir/meta.json")"
  gate="$(jq -r '.gate' "$dir/meta.json")"
  est="$(jq -r '.est_minutes' "$dir/meta.json")"
  objective="$(jq -r '.objective' "$dir/meta.json")"
  ws_path="workspace/$track/$id/"
  tag="$type"
  [[ "$gate" == "true" ]] && tag="$type · GATE"
  printf '\n%s %s — %s   %s · ~%s min\n' "$track" "$id" "$title" "$tag" "$est"
  printf -- '--------------------------------------------------------------\n'
  printf 'objective  %s\n' "$objective"
  printf 'workspace  %s\n' "$ws_path"
  printf '\nBRIEF\n'
  _extract_brief "$dir/lab.md"
  printf '\nsteps  less %s\n' "$dir/lab.md"
  printf 'next   lab check %s %s   (after finishing the GUIDED STEPS)\n' "$track" "$id"
}

render_recap_lines() {
  local lines_json="$1" line
  while IFS= read -r line; do
    printf '  · %s\n' "$line"
  done < <(jq -r '.[]' <<< "$lines_json")
}

recap_lines_json() {
  jq -R -s 'split("\n") | map(select(length > 0))' "$1/recap.md"
}

render_resume() {
  local last last_track last_id last_at last_recap title
  last="$(state_last_pass)"
  if [[ -z "$last" ]]; then
    printf 'nothing completed yet.\n\n'
    render_resume_next_up ""
    return 0
  fi
  last_track="$(jq -r '.track' <<< "$last")"
  last_id="$(jq -r '.id' <<< "$last")"
  last_at="$(jq -r '.at' <<< "$last")"
  last_recap="$(jq -c '.recap' <<< "$last")"
  title="$(catalog_meta "$last_track" "$last_id" "title" 2>/dev/null)"
  [[ -z "$title" ]] && title="$last_id"
  printf 'last passed  %s %s — %s   (%s)\n\n' "$last_track" "$last_id" "$title" "$last_at"
  printf '  recap\n'
  render_recap_lines "$last_recap"
  printf '\n'
  render_resume_next_up "$last_track"
}

render_resume_next_up() {
  local preferred_track="$1" track id title objective type est
  local order=()
  [[ -n "$preferred_track" ]] && order+=("$preferred_track")
  for track in $(catalog_tracks); do
    [[ "$track" == "$preferred_track" ]] && continue
    order+=("$track")
  done
  for track in "${order[@]}"; do
    id="$(catalog_frontier "$track")"
    if [[ -n "$id" ]]; then
      title="$(catalog_meta "$track" "$id" "title")"
      type="$(catalog_meta "$track" "$id" "type")"
      est="$(catalog_meta "$track" "$id" "est_minutes")"
      objective="$(catalog_meta "$track" "$id" "objective")"
      printf 'next up      %s %s — %s   (%s, ~%s min)\n' "$track" "$id" "$title" "$type" "$est"
      printf '             %s\n' "$objective"
      printf '             lab start %s %s\n' "$track" "$id"
      return 0
    fi
  done
  printf 'next up      nothing unlocked — every installed track is complete.\n'
}
