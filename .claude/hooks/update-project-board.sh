#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
command="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
stdout="$(printf '%s' "$payload" | jq -r '.tool_response.stdout // empty')"

pr_number="$(printf '%s' "$command" | grep -oE 'gh pr merge[[:space:]]+[0-9]+' | grep -oE '[0-9]+' || true)"
if [[ -z "$pr_number" ]]; then
  pr_number="$(printf '%s' "$stdout" | grep -oE '#[0-9]+' | head -1 | tr -d '#' || true)"
fi
if [[ -z "$pr_number" ]]; then
  exit 0
fi

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
owner="${repo%%/*}"

branch="$(gh pr view "$pr_number" -R "$repo" --json headRefName -q .headRefName 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  exit 0
fi

if [[ ! "$branch" =~ ^([a-z]+)-p[0-9]+-l([0-9]+\.[0-9]+)$ ]]; then
  exit 0
fi
track="${BASH_REMATCH[1]}"
lesson="L${BASH_REMATCH[2]}"

declare -A proj_num=( [bash]="18" [rust]="19" [soc]="20" [ps]="21" )
proj="${proj_num[$track]:-}"
if [[ -z "$proj" ]]; then
  exit 0
fi

declare -A proj_gid=(
  [18]="PVT_kwHODKiy2s4Bdn1z"
  [19]="PVT_kwHODKiy2s4Bdn4g"
  [20]="PVT_kwHODKiy2s4Bdn-M"
  [21]="PVT_kwHODKiy2s4Bdn_Q"
)
declare -A field_id=(
  [18]="PVTSSF_lAHODKiy2s4Bdn1zzhYIF4s"
  [19]="PVTSSF_lAHODKiy2s4Bdn4gzhYIIRE"
  [20]="PVTSSF_lAHODKiy2s4Bdn-MzhYINdc"
  [21]="PVTSSF_lAHODKiy2s4Bdn_QzhYIOb0"
)
done_option="98236657"

item_id="$(gh project item-list "$proj" --owner "$owner" --format json --limit 200 2>/dev/null \
  | jq -r --arg t "${lesson} " '.items[] | select(.content.title | startswith($t)) | .id' | head -1)"
if [[ -z "$item_id" ]]; then
  exit 0
fi

gh project item-edit --id "$item_id" --project-id "${proj_gid[$proj]}" \
  --field-id "${field_id[$proj]}" --single-select-option-id "$done_option" >/dev/null

printf '{"systemMessage": "Project board synced: %s -> project %s Done"}' "$lesson" "$proj"
