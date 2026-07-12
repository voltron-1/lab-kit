# shellcheck shell=bash
# lib/catalog.sh — everything derived from the tracks/ filesystem tree:
# track/phase/lab discovery, linear ordering, the next-unlocked frontier,
# and CLI-arity resolution. Never touches .progress.json directly; frontier
# math is delegated to lib/state.sh.

# Ordered TSV: phase \t n \t id \t dir  for one track. Empty output (not an
# error) if the track has no phases/ dir yet. Dies loudly on any lab
# directory that doesn't match the naming grammar — content is machine-built
# and a malformed dir means an authoring bug, never something to hide.
catalog_labs() {
  local track="$1"
  local phases_dir="$TRACKS_DIR/$track/phases"
  [[ -d "$phases_dir" ]] || return 0
  local labdir base id phase n rows
  rows=""
  while IFS= read -r -d '' labdir; do
    base="${labdir##*/}"
    if [[ ! "$base" =~ ^L([0-9]+)\.([0-9]+)-[a-z0-9-]+$ ]]; then
      die "malformed lab directory name: $labdir"
    fi
    phase="${BASH_REMATCH[1]}"
    n="${BASH_REMATCH[2]}"
    id="L${phase}.${n}"
    if [[ "$(basename "$(dirname "$labdir")")" != "p${phase}" ]]; then
      die "phase mismatch: $id lives under $(dirname "$labdir"), expected p${phase}"
    fi
    rows+="$phase"$'\t'"$n"$'\t'"$id"$'\t'"$labdir"$'\n'
  done < <(find "$phases_dir" -mindepth 2 -maxdepth 2 -type d -print0)
  [[ -z "$rows" ]] && return 0
  printf '%s' "$rows" | sort -t $'\t' -k1,1n -k2,2n
}

# Track names in display order (from track.json .order, missing/invalid
# falls back to 999 then alphabetical). Only directories carrying a
# track.json are "installed" — this is the sole source of the track list.
catalog_tracks() {
  local d name order
  for d in "$TRACKS_DIR"/*/; do
    [[ -f "${d}track.json" ]] || continue
    name="$(basename "$d")"
    order="$(jq -r '.order // 999' "${d}track.json" 2>/dev/null)"
    [[ "$order" =~ ^[0-9]+$ ]] || order=999
    printf '%s\t%s\n' "$order" "$name"
  done | sort -t $'\t' -k1,1n -k2,2 | cut -f2
}

catalog_track_title() {
  local track="$1"
  local f="$TRACKS_DIR/$track/track.json" title=""
  [[ -f "$f" ]] && title="$(jq -r '.title // empty' "$f")"
  printf '%s\n' "${title:-$track}"
}

catalog_phase_title() {
  local track="$1" phase="$2"
  local f="$TRACKS_DIR/$track/track.json" title=""
  [[ -f "$f" ]] && title="$(jq -r --arg p "$phase" '.phases[$p] // empty' "$f")"
  printf '%s\n' "$title"
}

# Resolve <track> <id> to its content directory, or die.
catalog_lab_dir() {
  local track="$1" id="$2" phase
  [[ "$id" =~ ^L([0-9]+)\.[0-9]+$ ]] || die "malformed lab id '$id'"
  phase="${BASH_REMATCH[1]}"
  local matches=() dir
  while IFS= read -r -d '' dir; do
    matches+=("$dir")
  done < <(find "$TRACKS_DIR/$track/phases/p$phase" -mindepth 1 -maxdepth 1 -type d -name "${id}-*" -print0 2>/dev/null)
  case "${#matches[@]}" in
    0) die "unknown lab '$id' in track '$track'" ;;
    1) printf '%s\n' "${matches[0]}" ;;
    *) die "multiple directories match '$id' in track '$track' — content is malformed" ;;
  esac
}

catalog_meta() {
  local track="$1" id="$2" field="$3" dir
  dir="$(catalog_lab_dir "$track" "$id")"
  jq -r --arg f "$field" '.[$f]' "$dir/meta.json"
}

# catalog_resolve <arg1> [<arg2>] → prints "track\tid" or dies.
# Two positionals: track+id, validated. One positional: must be a lab id;
# resolved by searching every installed track (0 hits/≥2 hits are errors).
# The single point where every cmd_* enforces "no more than track + id" —
# an extra stray argument (a typo'd flag, a leftover word) is a usage
# error, never silently ignored.
catalog_resolve() {
  [[ "$#" -le 2 ]] || die "too many arguments: $* (expected: [track] <id>)"
  local a="$1" b="${2:-}"
  local track id
  if [[ -n "$b" ]]; then
    track="$a"; id="$b"
    [[ -f "$TRACKS_DIR/$track/track.json" ]] || die "unknown track '$track'"
    catalog_lab_dir "$track" "$id" >/dev/null
    printf '%s\t%s\n' "$track" "$id"
    return 0
  fi
  id="$a"
  [[ "$id" =~ ^L([0-9]+)\.[0-9]+$ ]] || die "'$id' is not a valid lab id (expected form: L<phase>.<n>)"
  local phase="${BASH_REMATCH[1]}"
  local hits=() t
  for t in $(catalog_tracks); do
    if compgen -G "$TRACKS_DIR/$t/phases/p${phase}/${id}-*" >/dev/null 2>&1; then
      hits+=("$t")
    fi
  done
  case "${#hits[@]}" in
    0) die "no lab '$id' in any installed track (installed: $(catalog_tracks | paste -sd, -))" ;;
    1) printf '%s\t%s\n' "${hits[0]}" "$id" ;;
    *) die "$id exists in more than one track: $(printf '%s\n' "${hits[@]}" | paste -sd, -) — specify the track: lab start ${hits[0]} $id" ;;
  esac
}

# Ordered JSON array of a track's lab ids, for frontier math.
catalog_order_json() {
  local track="$1"
  catalog_labs "$track" | cut -f3 | jq -R -s 'split("\n") | map(select(length > 0))'
}

# First not-completed (not passed, not skipped) lab id in track order, or
# empty if the track is complete or has no labs yet.
catalog_frontier() {
  local track="$1" order_json
  order_json="$(catalog_order_json "$track")"
  [[ "$order_json" == "[]" ]] && return 0
  state_frontier "$track" "$order_json"
}

# All ids strictly before <id> in track order that are not yet completed —
# these are the labs a --force start would permanently mark skipped.
catalog_skip_candidates() {
  local track="$1" id="$2" order_json
  order_json="$(catalog_order_json "$track")"
  state_read | jq -c --arg t "$track" --arg id "$id" --argjson order "$order_json" '
    . as $st
    | ($order | index($id)) as $pos
    | $order[0:$pos]
    | map(select(
        ($st.labs[$t + "/" + .] // {status:null, skipped:false}) as $r
        | ($r.status != "passed") and ($r.skipped != true)
      ))'
}

# Cheap structural lint for one lab directory, run on the target of every
# start/check. Dies loudly rather than warn-and-skip: content is
# machine-built and malformed content is always an authoring bug.
catalog_lint_lab() {
  local track="$1" dir="$2" base id phase n
  base="${dir##*/}"
  id="${base%%-*}"
  [[ "$id" =~ ^L([0-9]+)\.([0-9]+)$ ]] || die "lab content bug: cannot parse id from $dir"
  phase="${BASH_REMATCH[1]}"
  n="${BASH_REMATCH[2]}"
  local f
  for f in meta.json lab.md quiz.json check.sh hints.json recap.md; do
    [[ -f "$dir/$f" ]] || die "lab content bug: $dir is missing $f"
  done
  local meta_id
  meta_id="$(jq -r '.id' "$dir/meta.json")"
  [[ "$meta_id" == "$id" ]] || die "lab content bug: $dir/meta.json id '$meta_id' does not match directory id '$id'"
  grep -q '^## BRIEF$' "$dir/lab.md" || die "lab content bug: $dir/lab.md is missing a '## BRIEF' heading"
  grep -q '^## GUIDED STEPS$' "$dir/lab.md" || die "lab content bug: $dir/lab.md is missing a '## GUIDED STEPS' heading"
  if [[ -f "$dir/recall.json" ]]; then
    local min_n
    min_n="$(catalog_labs "$track" | awk -F'\t' -v p="$phase" '$1==p {print $2}' | sort -n | head -n1)"
    [[ "$n" == "$min_n" ]] || die "lab content bug: $dir has recall.json but is not the first lab of phase p$phase"
  fi
}
