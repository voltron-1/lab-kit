# shellcheck shell=bash
# lib/session.sh — the interactive session: choose a track, decide resume vs
# start-over at a checkpoint, then work the labs without typing a lab id again.
#
# The session never re-implements grading. It shells out to the same cmd_start
# / cmd_check / cmd_hint the five commands use, in a subshell so their `exit`
# ends the command rather than the session. Every state write therefore goes
# through exactly the code path `lab start` and `lab check` already use.
#
# Two deliberate limits:
#   - "start from the beginning" moves the pointer only. Passes, ⏭ marks and
#     recaps are never cleared — the kit's skip marks are permanent by contract
#     (docs/kit-contracts.md), and a menu choice is not the place to erase them.
#   - The linear unlock rule still applies. The session picks the next lab for
#     you; it does not hand out labs past the frontier. `skip` is the one way
#     forward past a lab, and it marks ⏭ exactly like `lab start --force`.

SESSION_TRACK=""
SESSION_ID=""
SESSION_REQ_PATH=""

# Read one line into SESSION_REPLY. Returns 1 on EOF so callers can stop
# instead of spinning forever against a closed stdin.
session_read() {
  local prompt="$1"
  SESSION_REPLY=""
  printf '%s' "$prompt"
  IFS= read -r SESSION_REPLY || return 1
  return 0
}

# passed/total for a track, as "4/52"
_session_progress() {
  local track="$1" total passed
  total="$(catalog_labs "$track" | wc -l)"
  passed="$(state_bulk_tsv "$track" | awk -F'\t' '$2=="passed"' | wc -l)"
  printf '%s/%s' "$passed" "$total"
}

# Step 1 — accept the user's selected track. Sets SESSION_TRACK.
session_pick_track() {
  local tracks=() track i choice
  while IFS= read -r track; do tracks+=("$track"); done < <(catalog_tracks)
  [[ "${#tracks[@]}" -gt 0 ]] || die "no tracks installed under $TRACKS_DIR"

  if [[ "${#tracks[@]}" -eq 1 ]]; then
    SESSION_TRACK="${tracks[0]}"
    return 0
  fi

  printf '\n%sSelect a track%s\n' "$C_BOLD" "$C_RST"
  for i in "${!tracks[@]}"; do
    track="${tracks[$i]}"
    printf '  %s) %-6s %-24s (%s)\n' \
      "$((i + 1))" "$track" "$(catalog_track_title "$track")" "$(_session_progress "$track")"
  done
  printf '\n'

  while true; do
    session_read "track (number or name, q to quit) > " || { printf '\n'; return 1; }
    choice="${SESSION_REPLY// /}"
    case "$choice" in
      q | quit | "") return 1 ;;
    esac
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le "${#tracks[@]}" ]]; then
      SESSION_TRACK="${tracks[$((choice - 1))]}"
      return 0
    fi
    for track in "${tracks[@]}"; do
      if [[ "$choice" == "$track" ]]; then
        SESSION_TRACK="$track"
        return 0
      fi
    done
    warn "no such track '$choice' — pick a number or one of: ${tracks[*]}"
  done
}

# The most recent pass event recorded for this track (state_last_pass is
# global across tracks, and a checkpoint is per-track by definition).
_session_last_pass() {
  local track="$1"
  state_read | jq -c --arg t "$track" \
    '.events | map(select(.type == "pass" and .track == $t)) | last // empty'
}

# Step 2/3 — the checkpoint decision. Sets SESSION_ID to the lab to open.
session_checkpoint() {
  local track="$1" frontier first last last_id last_at title
  frontier="$(catalog_frontier "$track")"
  first="$(catalog_labs "$track" | head -1 | cut -f3)"
  [[ -n "$first" ]] || die "track '$track' has no labs"

  printf '\n%s%s · %s%s   %s\n' \
    "$C_BOLD" "$track" "$(catalog_track_title "$track")" "$C_RST" "$(_session_progress "$track")"

  last="$(_session_last_pass "$track")"
  if [[ -n "$last" && "$last" != "null" ]]; then
    last_id="$(jq -r '.id' <<< "$last")"
    last_at="$(jq -r '.at' <<< "$last")"
    printf '  last checkpoint  %s — %s   (%s)\n' \
      "$last_id" "$(catalog_meta "$track" "$last_id" "title" 2> /dev/null || printf '%s' "$last_id")" "$last_at"
  else
    printf '  last checkpoint  none yet\n'
  fi

  if [[ -n "$frontier" ]]; then
    title="$(catalog_meta "$track" "$frontier" "title")"
    printf '\n  1) Resume from last saved checkpoint   → %s %s\n' "$frontier" "$title"
  else
    printf '\n  1) Resume from last saved checkpoint   → track complete, nothing to resume\n'
  fi
  printf '  2) Start from the beginning            → %s %s\n' \
    "$first" "$(catalog_meta "$track" "$first" "title")"
  printf '     (moves where you start; your %s passes and %s marks are kept)\n\n' "$MARK_PASS" "$MARK_SKIPPED"

  while true; do
    session_read "choice (1, 2, q to quit) > " || { printf '\n'; return 1; }
    case "${SESSION_REPLY// /}" in
      1 | resume)
        if [[ -z "$frontier" ]]; then
          warn "'$track' is complete — nothing to resume. Choose 2 to work it again."
          continue
        fi
        # Restore the context too, not just the pointer: the recap of the last
        # lab you passed is what `lab resume` exists to put back in your head.
        if [[ -n "$last" && "$last" != "null" ]]; then
          printf '\n  where you left off — recap of %s\n' "$last_id"
          render_recap_lines "$(jq -c '.recap' <<< "$last")"
        fi
        SESSION_ID="$frontier"
        return 0
        ;;
      2 | beginning | restart)
        SESSION_ID="$first"
        return 0
        ;;
      q | quit | "") return 1 ;;
      *) warn "answer 1 or 2" ;;
    esac
  done
}

# The lab that follows $2 in $1's catalog order; empty at the end of the track.
_session_next_lab() {
  local track="$1" id="$2"
  catalog_labs "$track" | cut -f3 | awk -v cur="$id" 'found {print; exit} $0==cur {found=1}'
}

# _session_confine_path <track> <id> <name> — sets SESSION_REQ_PATH to the
# canonicalized path inside the lab's workspace, or warns and returns 1 if
# <name> resolves outside it. Mirrors harness/checklib.sh's
# require_in_workspace (same realpath -m + prefix-match idiom); reimplemented
# locally since that one is checklib/$LAB_WORKSPACE-scoped and this runs in
# the session process, not inside a fenced check.sh.
#
# Transparently strips a leading "files/" — GUIDED STEPS text says
# "files/x.json" but ws_provision() copies files/. flat into the workspace
# root, so the on-disk path never actually has that prefix. Stripping it
# means `show files/persistence-legend.md` (pasted straight from the brief)
# and `show persistence-legend.md` both just work.
_session_confine_path() {
  local track="$1" id="$2" name="${3#files/}" ws canon
  ws="$(ws_path "$track" "$id")"
  canon="$(realpath -m -- "$ws/$name" 2> /dev/null)" || { warn "no such file: $3"; return 1; }
  case "$canon" in
    "$ws" | "$ws"/*)
      SESSION_REQ_PATH="$canon"
      return 0
      ;;
    *)
      warn "no such file in this lab's workspace: $3"
      return 1
      ;;
  esac
}

# Step 4 — hand control to the labs. The learner drives from here.
session_lab_loop() {
  local track="$1" id="$2" rc next in_order started="" cmd arg ws

  while [[ -n "$id" ]]; do
    if [[ "$started" != "$id" ]]; then
      if ! (cmd_start "$track" "$id"); then
        warn "could not open $track $id"
        return 2
      fi
      started="$id"
    fi

    printf '\n%s%s %s%s — check · hint · brief · files · show · edit · skip · quit\n' \
      "$C_BOLD" "$track" "$id" "$C_RST"
    session_read "> " || { printf '\nsession closed — progress saved.\n'; return 0; }

    # Split into a command word and its (optional) argument. `show`/`edit`
    # need the argument verbatim; every other command ignores it, same as
    # before this split existed (extra trailing text was simply part of a
    # non-matching token and fell to the unknown-command case).
    cmd="" arg=""
    read -r cmd arg <<< "$SESSION_REPLY" || true

    case "$cmd" in
      check | c)
        rc=0
        (cmd_check "$track" "$id") || rc=$?
        if [[ "$rc" -eq 0 ]]; then
          next="$(catalog_frontier "$track")"
          # Walking forward from an earlier lab must not teleport to the
          # frontier: take the next lab in order unless it is already behind us.
          in_order="$(_session_next_lab "$track" "$id")"
          # NB: a bare `[[ ... ]] && next=...` would abort the whole session
          # under `set -e` on the last lab of a track, where in_order is empty.
          if [[ -n "$in_order" ]]; then next="$in_order"; fi
          if [[ -z "$next" ]]; then
            printf '\n%s track complete — nothing left to open.\n' "$track"
            return 0
          fi
          id="$next"
        elif [[ "$rc" -ge 2 ]]; then
          warn "grader problem on $track $id — leaving the session so it can be reported"
          return "$rc"
        fi
        ;;
      hint | h) (cmd_hint "$track" "$id") || true ;;
      brief | b) render_brief "$track" "$id" ;;
      files | ls) render_ws_listing "$track" "$id" ;;
      show)
        if [[ -z "$arg" ]]; then
          warn "usage: show <file>   (try: files)"
        elif _session_confine_path "$track" "$id" "$arg"; then
          if [[ -f "$SESSION_REQ_PATH" ]]; then
            printf '\n'
            cat -- "$SESSION_REQ_PATH" || warn "could not read $arg"
          else
            warn "no such file: $arg"
          fi
        fi
        ;;
      edit)
        if [[ -z "$arg" ]]; then
          warn "usage: edit <file>   (try: files)"
        elif _session_confine_path "$track" "$id" "$arg"; then
          ws="$(ws_path "$track" "$id")"
          # `|| true`: a nonzero editor exit (unset $EDITOR falling through
          # to a missing `vi`, or the learner just :cq-ing out) must not
          # trip the session's own `set -e` and kill the whole loop.
          ( cd -- "$ws" && "${EDITOR:-vi}" -- "$SESSION_REQ_PATH" ) || warn "editor exited non-zero"
        fi
        ;;
      skip | s)
        next="$(_session_next_lab "$track" "$id")"
        if [[ -z "$next" ]]; then
          printf 'nothing after %s in %s.\n' "$id" "$track"
          continue
        fi
        printf '%s skipping %s marks it %s permanently — it can never show %s.\n' \
          "$MARK_SKIPPED" "$id" "$MARK_SKIPPED" "$MARK_PASS"
        session_read "skip $id? (y/N) > " || { printf '\n'; return 0; }
        if [[ "${SESSION_REPLY// /}" =~ ^[Yy]$ ]]; then
          if (cmd_start "$track" "$next" --force); then
            id="$next"
            started="$id"
          else
            warn "could not skip to $next"
          fi
        fi
        ;;
      status) render_status ;;
      quit | q | "")
        printf 'session closed — progress saved. Pick up with: lab\n'
        return 0
        ;;
      *) warn "commands: check · hint · brief · files · show <file> · edit <file> · skip · status · quit" ;;
    esac
  done
  return 0
}

# The whole flow, enforced in order for every session initialization.
session_run() {
  if [[ ! -t 0 ]]; then
    # No terminal to drive the menus — behave like the old bare `lab`.
    usage
    return 0
  fi
  printf '%sLAB-KIT%s — interactive session\n' "$C_BOLD" "$C_RST"
  session_pick_track || { printf 'nothing selected.\n'; return 0; }
  session_checkpoint "$SESSION_TRACK" || { printf 'nothing selected.\n'; return 0; }
  session_lab_loop "$SESSION_TRACK" "$SESSION_ID"
}
