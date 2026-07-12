# shellcheck shell=bash
# lib/quiz.sh — quiz_run (3 questions, gates `lab check`) and recall_run
# (5 questions, non-gating warm-up run by `lab start` on phase-openers).
# Plain `IFS= read -r` from stdin, one line per question, no /dev/tty, no
# reprompt — so `printf 'a\nb\nc\n' | lab check ...` behaves identically to
# typing. End-of-run verdict only; a miss is reported by question number,
# never by revealing the correct answer.

quiz_normalize() {
  local s="${1,,}"
  s="$(printf '%s' "$s" | tr -s '[:space:]' ' ')"
  s="${s# }"; s="${s% }"
  printf '%s' "$s"
}

quiz_decode_b64() {
  printf '%s' "$1" | base64 -d 2>/dev/null || true
}

# _quiz_grade_one <question_json> <label> — prints "<label>. <prompt>" (+
# choices for "choice" type), reads exactly one line, grades it. Returns
# 0 (correct) or 1 (wrong/blank/EOF). Never prints right/wrong feedback or
# the answer itself.
_quiz_grade_one() {
  local qjson="$1" label="$2" type prompt reply norm expect case_sensitive alt_json
  type="$(jq -r '.type' <<< "$qjson")"
  prompt="$(jq -r '.prompt' <<< "$qjson")"
  printf '%s. %s\n' "$label" "$prompt"
  if [[ "$type" == "choice" ]]; then
    while IFS=$'\t' read -r key val; do
      printf '      %s) %s\n' "$key" "$val"
    done < <(jq -r '.options | to_entries[] | [.key, .value] | @tsv' <<< "$qjson")
  fi
  printf '  > '
  IFS= read -r reply || reply=""
  case_sensitive="$(jq -r '.case_sensitive // false' <<< "$qjson")"

  if [[ "$type" == "choice" ]]; then
    norm="$(quiz_normalize "$reply")"
    norm="${norm:0:1}"
    expect="$(quiz_decode_b64 "$(jq -r '.answer_b64' <<< "$qjson")")"
    [[ "$norm" == "$expect" ]] && return 0 || return 1
  fi

  if [[ "$case_sensitive" == "true" ]]; then
    norm="$reply"
  else
    norm="$(quiz_normalize "$reply")"
  fi
  expect="$(quiz_decode_b64 "$(jq -r '.answer_b64' <<< "$qjson")")"
  [[ "$case_sensitive" != "true" ]] && expect="$(quiz_normalize "$expect")"
  [[ "$norm" == "$expect" ]] && return 0

  alt_json="$(jq -c '.accept_b64 // []' <<< "$qjson")"
  local alt_b64 alt
  while IFS= read -r alt_b64; do
    [[ -z "$alt_b64" ]] && continue
    alt="$(quiz_decode_b64 "$alt_b64")"
    [[ "$case_sensitive" != "true" ]] && alt="$(quiz_normalize "$alt")"
    [[ "$norm" == "$alt" ]] && return 0
  done < <(jq -r '.[]' <<< "$alt_json")
  return 1
}

# quiz_run <track> <id> <lab_dir> — returns 0 iff all questions correct.
quiz_run() {
  local lab_dir="$3" quiz_file
  quiz_file="$lab_dir/quiz.json"
  local total correct=0 i n qjson
  local -a missed=()
  total="$(jq '.questions | length' "$quiz_file")"
  printf '\nquiz — %s questions\n' "$total"
  printf -- '--------------------------------------------------------------\n'
  for ((i = 0; i < total; i++)); do
    n=$((i + 1))
    qjson="$(jq -c ".questions[$i]" "$quiz_file")"
    if _quiz_grade_one "$qjson" "Q$n"; then
      correct=$((correct + 1))
    else
      missed+=("Q$n")
    fi
  done
  printf '\n'
  if [[ "$correct" -eq "$total" ]]; then
    printf 'quiz: %d/%d\n' "$correct" "$total"
    return 0
  fi
  printf 'quiz: %d/%d (missed %s)\n' "$correct" "$total" "$(IFS=,; echo "${missed[*]}")"
  return 1
}

# recall_run <track> <id> <lab_dir> — non-gating; always returns 0. Prints
# the score and a "review:" pointer per miss, never gates `lab start`.
recall_run() {
  local lab_dir="$3" recall_file
  recall_file="$lab_dir/recall.json"
  [[ -f "$recall_file" ]] || return 0

  local total correct=0 i n qjson src
  local -a missed=() miss_src=()
  total="$(jq '.questions | length' "$recall_file")"
  printf '\nrecall — %s questions from earlier material\n' "$total"
  printf -- '--------------------------------------------------------------\n'
  for ((i = 0; i < total; i++)); do
    n=$((i + 1))
    qjson="$(jq -c ".questions[$i]" "$recall_file")"
    if _quiz_grade_one "$qjson" "R$n"; then
      correct=$((correct + 1))
    else
      missed+=("R$n")
      src="$(jq -r '.source // empty' <<< "$qjson")"
      [[ -n "$src" ]] && miss_src+=("$src")
    fi
  done
  printf '\n'
  if [[ "$total" -gt 0 && "$correct" -ge $(( (total * 4 + 4) / 5 )) ]]; then
    printf 'recall: %d/%d — pass\n' "$correct" "$total"
  else
    printf 'recall: %d/%d (missed %s)\n' "$correct" "$total" "$(IFS=,; echo "${missed[*]}")"
  fi
  local s
  for s in "${miss_src[@]}"; do
    printf '  review: %s\n' "$s"
  done
  return 0
}
