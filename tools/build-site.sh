#!/usr/bin/env bash
# tools/build-site.sh — bundle tracks/soc into one playable HTML page.
#
#   tools/build-site.sh [--out PATH]          build (default docs/site/soc.html)
#   tools/build-site.sh --check               build to a temp file and cmp with
#                                             the committed page; exit 1 if stale
#   tools/build-site.sh --data-only PATH      write the JSON bundle alone
#
# Each lab's check.sh is run once against a pristine workspace with
# harness/checklib-record.sh standing in for the real checklib, so the
# assertions the page replays are exactly the ones the bash grader makes.
# Needs bash + jq; tshark is used for pcap renderings when present.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/docs/site/src"
TRACK_DIR="$ROOT/tracks/soc"
RECORD_LIB="$ROOT/harness/checklib-record.sh"
DEFAULT_OUT="$ROOT/docs/site/soc.html"

if locale -a 2>/dev/null | grep -qix 'c\.utf-\?8'; then
  export LC_ALL=C.UTF-8
else
  export LC_ALL=C
fi

die() { printf 'build-site: %s\n' "$*" >&2; exit 2; }
warn() { printf 'build-site: warning: %s\n' "$*" >&2; }

OUT="$DEFAULT_OUT"
MODE=build
DATA_OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) [[ $# -ge 2 ]] || die "--out needs a path"; OUT="$2"; shift 2 ;;
    --check) MODE=check; shift ;;
    --data-only) [[ $# -ge 2 ]] || die "--data-only needs a path"; MODE=data; DATA_OUT="$2"; shift 2 ;;
    -h|--help) sed -n 2,12p "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || die "jq is required"
[[ -d "$TRACK_DIR/phases" ]] || die "missing $TRACK_DIR/phases"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

HAVE_TSHARK=0
TSHARK_VER="none"
if command -v tshark >/dev/null 2>&1; then
  HAVE_TSHARK=1
  TSHARK_VER="$(tshark --version 2>/dev/null | head -n 1 || true)"
  [[ -n "$TSHARK_VER" ]] || TSHARK_VER="unknown"
fi

# --check on a machine whose tshark differs from the one that built the
# committed page reuses the committed pcap renderings, so a different tshark
# release never reads as a stale page.
COMMITTED_RENDER=""
if [[ "$MODE" == check && -f "$DEFAULT_OUT" ]]; then
  committed_bundle="$TMP/committed.json"
  awk '/<script id="lab-data" type="application\/json">/{f=1; next} f && /<\/script>/{exit} f{print}' \
    "$DEFAULT_OUT" > "$committed_bundle"
  if jq -e . "$committed_bundle" >/dev/null 2>&1; then
    committed_ver="$(jq -r '.build.tshark // "none"' "$committed_bundle")"
    if [[ "$HAVE_TSHARK" -eq 0 || "$committed_ver" != "$TSHARK_VER" ]]; then
      COMMITTED_RENDER="$committed_bundle"
      TSHARK_VER="$committed_ver"
    fi
  fi
fi

magic_label() {
  local hex
  hex="$(od -An -tx1 -N8 -- "$1" | tr -d ' \n')"
  case "$hex" in
    504b0304*|504b0506*|504b0708*) printf 'zip (PK)' ;;
    d0cf11e0*) printf 'ole (D0CF11E0)' ;;
    4d5a*) printf 'pe (MZ)' ;;
    ffd8*) printf 'jpeg (FFD8)' ;;
    89504e47*) printf 'png (89504E47)' ;;
    25504446*) printf 'pdf (%%PDF)' ;;
    d4c3b2a1*|a1b2c3d4*|0a0d0d0a*) printf 'pcap capture' ;;
    *) printf 'unknown' ;;
  esac
}

# render_pcap <lab_id> <relname> <file> — text view of a capture.
render_pcap() {
  local id="$1" name="$2" f="$3"
  if [[ -n "$COMMITTED_RENDER" ]]; then
    jq -r --arg id "$id" --arg n "$name" \
      '.labs[] | select(.id == $id) | .files[] | select(.name == $n) | .rendered // ""' \
      "$COMMITTED_RENDER"
    return 0
  fi
  if [[ "$HAVE_TSHARK" -eq 1 ]]; then
    tshark -r - < "$f" 2>/dev/null || true
    if [[ "$id" == "L2.4" ]]; then
      printf '\n--- tcp stream 0 (follow) ---\n'
      tshark -r - -z follow,tcp,ascii,0 -q < "$f" 2>/dev/null || true
    fi
  else
    od -A x -t x1z -v -- "$f"
  fi
}

# --- normalisers ---------------------------------------------------------
# One JSON object per `tr ... < SRC ... > TARGET` line in a check.sh.
norms_json() {
  local check="$1" line src target comment nows trim sortkey=""
  grep -q 'raw_q4' "$check" && sortkey="q4"
  while IFS= read -r line; do
    [[ "$line" =~ \<\ ([A-Za-z0-9._/-]+)\  ]] || continue
    src="${BASH_REMATCH[1]}"
    [[ "$line" =~ \>\ (\.[A-Za-z0-9._-]+)$ ]] || continue
    target="${BASH_REMATCH[1]}"
    comment=false nows=false trim=false
    [[ "$line" == *"sed 's@#.*@@'"* ]] && comment=true
    [[ "$line" == *"tr -d '\\r \\t'"* ]] && nows=true
    [[ "$line" == *'[[:space:]]*$'* ]] && trim=true
    jq -nc --arg s "$src" --arg t "$target" --argjson c "$comment" --argjson n "$nows" \
      --argjson r "$trim" --arg k "$sortkey" '
      {source: $s, target: $t, comment: $c, nows: $n, trim: $r,
       variant: (if $n then "nows" elif $c then "standard" else "report" end)}
      + (if $k != "" and $s == "answers.txt" then {sort_csv: $k} else {} end)'
  done < <(grep -E "tr '\[:upper:\]' '\[:lower:\]' < " "$check" || true)
}

# find_prefill <files_dir> <graded_name> — echo the template's relative name.
find_prefill() {
  local dir="$1" name="$2" base ext cand
  base="${name%.*}"
  ext="${name##*.}"
  if [[ "$name" == *.* ]]; then
    for cand in "$base.template.$ext" "$base-template.$ext" "$name.template"; do
      [[ -f "$dir/$cand" ]] && { printf '%s' "$cand"; return 0; }
    done
  else
    [[ -f "$dir/$name.template" ]] && { printf '%s' "$name.template"; return 0; }
  fi
  if [[ "$name" == "report.md" ]]; then
    cand="$(cd -- "$dir" && find . -maxdepth 1 -type f -name '*template*.md' | sed 's@^\./@@' | LC_ALL=C sort | head -n 1)"
    [[ -n "$cand" ]] && { printf '%s' "$cand"; return 0; }
  fi
  return 0
}

# --- per-lab bundle ------------------------------------------------------
build_lab() {
  local dir="$1" idx="$2" id ws rec rc lines=0
  id="$(jq -r '.id' "$dir/meta.json")"
  ws="$TMP/ws-$idx"
  mkdir -p -- "$ws"
  [[ -d "$dir/files" ]] && cp -R -- "$dir/files/." "$ws/"

  # Some graders `tr < answers.txt` unguarded and would abort before the
  # later assertions; give every redirected input a stub so the recording
  # run always reaches the end.
  local stub
  while IFS= read -r stub; do
    [[ -z "$stub" || "$stub" == /dev/* ]] && continue
    if [[ ! -e "$ws/$stub" ]]; then
      printf 'q1=\nq2=\nq3=\nq4=\nq5=\nq6=\nq7=\nq8=\nq9=\n' > "$ws/$stub"
    fi
  done < <(grep -oE '< [A-Za-z0-9._-]+' "$dir/check.sh" | cut -c3- | LC_ALL=C sort -u || true)

  rec="$TMP/rec-$idx.jsonl"
  : > "$rec"
  rc=0
  ( cd -- "$ws" \
    && LAB_WORKSPACE="$ws" LAB_CHECKLIB="$RECORD_LIB" LAB_RECORD_OUT="$rec" \
       bash --noprofile --norc -euo pipefail -- "$dir/check.sh" < /dev/null >/dev/null 2>&1 ) || rc=$?
  lines="$(wc -l < "$rec" | tr -d ' ')"
  [[ "$rc" -ne 0 ]] && warn "$id: check.sh exited $rc under the recorder ($lines assertions kept)"

  local ungradable=false
  if [[ "$lines" -eq 0 ]]; then
    ungradable=true
    printf '%s\n' "$id" >> "$TMP/ungradable.txt"
  fi

  # Evidence list and template claims.
  local fdir="$dir/files" f rel size sha b64 kind magic
  local tfiles="$TMP/files-$idx.jsonl"
  : > "$tfiles"
  local -a graded=()
  local -A claimed=()
  local path norm_src
  # graded file names: assertion paths that are not in files/ and not .norm
  local norms
  norms="$(norms_json "$dir/check.sh" | jq -sc '.')"
  [[ -n "$norms" ]] || norms="[]"
  while IFS= read -r path; do
    [[ -z "$path" || "$path" == null ]] && continue
    if [[ "$path" =~ ^\..*\.norm$ ]]; then
      norm_src="$(jq -r --arg t "$path" '.[] | select(.target == $t) | .source' <<< "$norms" | head -n 1)"
      [[ -n "$norm_src" ]] || continue
      path="$norm_src"
    fi
    [[ -f "$fdir/$path" ]] && continue
    graded+=("$path")
  done < <(jq -r '.path // empty' "$rec" | LC_ALL=C sort -u)
  # norm sources are graded even if only asserted through the .norm file
  while IFS= read -r norm_src; do
    [[ -z "$norm_src" || -f "$fdir/$norm_src" ]] && continue
    graded+=("$norm_src")
  done < <(jq -r '.[].source' <<< "$norms")
  if [[ "${#graded[@]}" -gt 0 ]]; then
    mapfile -t graded < <(printf '%s\n' "${graded[@]}" | LC_ALL=C sort -u)
  fi

  local gtmp="$TMP/graded-$idx.jsonl" prefill_rel prefill_text expected
  : > "$gtmp"
  local g
  for g in "${graded[@]}"; do
    prefill_rel="$(find_prefill "$fdir" "$g")"
    prefill_text=""
    if [[ -n "$prefill_rel" ]]; then
      prefill_text="$(cat -- "$fdir/$prefill_rel"; printf x)"
      prefill_text="${prefill_text%x}"
      claimed["$prefill_rel"]=1
    fi
    expected=""
    if [[ -z "$prefill_rel" ]]; then
      expected="$(expected_for "$rec" "$g")"
    fi
    jq -nc --arg n "$g" --arg p "$prefill_text" --arg e "$expected" --arg t "$prefill_rel" \
      '{name: $n, prefill: $p, expected: $e, template: $t, tool_output: ($t == "" and ($e != ""))}' >> "$gtmp"
  done

  if [[ -d "$fdir" ]]; then
    while IFS= read -r f; do
      rel="${f#"$fdir"/}"
      [[ -n "${claimed[$rel]:-}" ]] && continue
      size="$(wc -c < "$f" | tr -d ' ')"
      if [[ "$size" -eq 0 ]] || grep -qI -- '' "$f"; then
        { jq -nc --arg n "$rel" --argjson s "$size" --rawfile t "$f" \
            '{name: $n, size: $s, kind: "text", text: $t}'; } >> "$tfiles"
      else
        sha="$(sha256sum -- "$f" | cut -d' ' -f1)"
        b64="$(base64 -w0 -- "$f")"
        magic="$(magic_label "$f")"
        kind=binary
        [[ "$rel" == *.pcap ]] && kind=pcap
        if [[ "$kind" == pcap ]]; then
          render_pcap "$id" "$rel" "$f" > "$TMP/render.txt"
          jq -nc --arg n "$rel" --argjson s "$size" --arg k "$kind" --arg b "$b64" --arg h "$sha" \
            --arg m "$magic" --rawfile r "$TMP/render.txt" \
            '{name: $n, size: $s, kind: $k, b64: $b, sha256: $h, magic: $m, rendered: $r}' >> "$tfiles"
        else
          jq -nc --arg n "$rel" --argjson s "$size" --arg k "$kind" --arg b "$b64" --arg h "$sha" \
            --arg m "$magic" \
            '{name: $n, size: $s, kind: $k, b64: $b, sha256: $h, magic: $m}' >> "$tfiles"
        fi
      fi
    done < <(find "$fdir" -type f | LC_ALL=C sort)
  fi

  local recall_args=()
  if [[ -f "$dir/recall.json" ]]; then
    recall_args=(--slurpfile recall "$dir/recall.json")
  else
    recall_args=(--argjson recall '[]')
  fi

  local base
  base="$(basename -- "$dir")"
  jq -nc \
    --slurpfile meta "$dir/meta.json" \
    --rawfile lab "$dir/lab.md" \
    --slurpfile quiz "$dir/quiz.json" \
    --slurpfile hints "$dir/hints.json" \
    --rawfile recap "$dir/recap.md" \
    "${recall_args[@]}" \
    --slurpfile assertions "$rec" \
    --slurpfile files "$tfiles" \
    --slurpfile graded "$gtmp" \
    --argjson norms "$norms" \
    --argjson ungradable "$ungradable" \
    --arg dir "$base" \
    '$meta[0] as $m
     | ($m.id | capture("^L(?<p>[0-9]+)\\.(?<n>[0-9]+)$")) as $pn
     | {id: $m.id,
        dir: $dir,
        phase: ("p" + $pn.p),
        order: [($pn.p | tonumber), ($pn.n | tonumber)],
        meta: $m,
        lab_md: $lab,
        quiz: $quiz[0].questions,
        hints: $hints[0].hints,
        recap: ($recap | split("\n") | map(select(length > 0))),
        recall: (if ($recall | type) == "array" and ($recall | length) > 0
                 then (if ($recall[0] | type) == "object" then $recall[0].questions else $recall end)
                 else null end),
        ungradable: $ungradable,
        assertions: $assertions,
        norms: $norms,
        graded_files: $graded,
        files: $files}'
}

# expected_for <record> <graded_name> — "fill from expected output": the
# literals a tool's output file must contain (plain-literal regexes count too).
expected_for() {
  local rec="$1" g="$2"
  jq -rs --arg p "$g" '
    def lit: ltrimstr("^") | rtrimstr("$") | gsub("\\[0-9\\]"; "1") | gsub("\\\\\\."; ".");
    [ .[] | select(.path == $p)
      | if .fn == "contains_fixed" then .arg
        elif .fn == "contains" then
          (.arg | lit) as $l
          | if ($l | test("[\\[\\]()|*+?{}\\\\^$]")) then empty else $l end
        else empty end ]
    | join("\n")' "$rec"
}

# --- assemble ------------------------------------------------------------
mapfile -t LAB_DIRS < <(find "$TRACK_DIR/phases" -mindepth 2 -maxdepth 2 -type d -name 'L*' | LC_ALL=C sort)
[[ "${#LAB_DIRS[@]}" -gt 0 ]] || die "no labs found under $TRACK_DIR/phases"

: > "$TMP/labs.jsonl"
i=0
for d in "${LAB_DIRS[@]}"; do
  i=$((i + 1))
  build_lab "$d" "$i" >> "$TMP/labs.jsonl"
done

if [[ "$HAVE_TSHARK" -eq 0 && -z "$COMMITTED_RENDER" ]]; then
  warn "tshark not found: pcap renderings are hex dumps"
fi

jq -sc --slurpfile track "$TRACK_DIR/track.json" --arg tshark "$TSHARK_VER" '
  {build: {tshark: $tshark, labs: length},
   track: $track[0],
   labs: (sort_by(.order))}' "$TMP/labs.jsonl" > "$TMP/bundle.json"

if [[ -s "$TMP/ungradable.txt" ]]; then
  warn "ungradable labs (no recorded assertions): $(tr '\n' ' ' < "$TMP/ungradable.txt")"
fi

if [[ "$MODE" == data ]]; then
  cp -- "$TMP/bundle.json" "$DATA_OUT"
  exit 0
fi

# Safe to embed inside a <script> element: </ and <!-- never appear raw.
sed -e 's@</@<\\/@g' -e 's@<!--@<\\u0021--@g' "$TMP/bundle.json" > "$TMP/bundle.safe.json"

for part in index.html app.js style.css; do
  [[ -f "$SRC/$part" ]] || die "missing $SRC/$part"
done

BUILD_TMP="$TMP/soc.html"
awk -v style="$SRC/style.css" -v data="$TMP/bundle.safe.json" -v app="$SRC/app.js" '
  function dump(path,   line) {
    while ((getline line < path) > 0) print line
    close(path)
  }
  $0 == "<!--STYLE-->" { dump(style); next }
  $0 == "<!--DATA-->"  { dump(data);  next }
  $0 == "<!--APP-->"   { dump(app);   next }
  { print }
' "$SRC/index.html" > "$BUILD_TMP"

if [[ -n "${LAB_SITE_SALT:-}" ]]; then
  printf '<!-- salt: %s -->\n' "${LAB_SITE_SALT//--/-}" >> "$BUILD_TMP"
fi

if [[ "$MODE" == check ]]; then
  if [[ -f "$DEFAULT_OUT" ]] && cmp -s -- "$BUILD_TMP" "$DEFAULT_OUT"; then
    echo "build-site: $DEFAULT_OUT is current"
    exit 0
  fi
  echo "build-site: $DEFAULT_OUT is stale — run ./tools/build-site.sh" >&2
  exit 1
fi

mkdir -p -- "$(dirname -- "$OUT")"
cp -- "$BUILD_TMP" "$OUT"
echo "build-site: wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes, $(jq -r '.build.labs' "$TMP/bundle.json") labs)"
