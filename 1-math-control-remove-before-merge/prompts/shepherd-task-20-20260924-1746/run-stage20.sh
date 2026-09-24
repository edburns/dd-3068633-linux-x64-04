#!/usr/bin/env bash

set -uo pipefail

REPO='edburns/dd-3068633-linux-x64-04'
PARENT_ISSUE='1'
LOG_DIRECTORY='/home/edburns/workareas/dd-3068633-linux-x64-04-shepherd-control/1-math-control-remove-before-merge/prompts/shepherd-task-20-20260924-1746'
BODY_DIRECTORY="$LOG_DIRECTORY/issue-bodies"
LEDGER="$LOG_DIRECTORY/creation-ledger.json"
RESULT="$LOG_DIRECTORY/stage-20-result.json"
BASELINE="$LOG_DIRECTORY/pre-creation-children.json"
VERIFIER='/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh'

atomic_write() {
  local path="$1" content="$2" temporary
  temporary="$(mktemp "$LOG_DIRECTORY/.stage20.XXXXXX")" || return 1
  printf '%s\n' "$content" >"$temporary" || {
    rm -f "$temporary"
    return 1
  }
  mv "$temporary" "$path"
}

normalize_pages() {
  jq 'if length == 0 then [] elif all(.[]; type == "array") then add else . end'
}

update_ledger_flag() {
  local number="$1" field="$2" value="$3" updated
  updated="$(
    jq \
      --argjson number "$number" \
      --arg field "$field" \
      --argjson value "$value" \
      'map(if .number == $number then .[$field] = $value else . end)' \
      "$LEDGER"
  )" || return 1
  atomic_write "$LEDGER" "$updated"
}

reconcile_and_fail() {
  local operation="$1" error="$2" pages flat updated result_json entry number
  if pages="$(gh api "repos/$REPO/issues/$PARENT_ISSUE/sub_issues" --paginate --slurp 2>&1)"; then
    if flat="$(printf '%s\n' "$pages" | normalize_pages 2>&1)"; then
      updated="$(
        jq \
          --argjson children "$flat" \
          'map(. as $entry | .linked = any($children[]; .id == $entry.id))' \
          "$LEDGER" 2>&1
      )"
      if [[ $? -eq 0 ]]; then
        atomic_write "$LEDGER" "$updated" || error="$error; unable to persist reconciled ledger"
      else
        error="$error; reconciliation jq failed: $updated"
      fi
    else
      error="$error; unable to normalize reconciliation response: $flat"
    fi
  else
    error="$error; unable to query children during reconciliation: $pages"
  fi

  while IFS= read -r entry; do
    number="$(jq -r '.number' <<<"$entry")"
    if ! gh api "repos/$REPO/issues/$number" >/dev/null 2>&1; then
      error="$error; unable to reconcile issue #$number"
    fi
  done < <(jq -c '.[]' "$LEDGER")

  result_json="$(
    jq -n \
      --arg operationError "$operation: $error" \
      '{schemaVersion:1,status:"failed",ledgerFile:"creation-ledger.json",operationError:$operationError}'
  )"
  atomic_write "$RESULT" "$result_json" || true

  printf 'FAILED OPERATION: %s\nERROR: %s\n\n' "$operation" "$error" >&2
  if [[ "$(jq 'length' "$LEDGER")" -eq 0 ]]; then
    printf 'No issues were created; no cleanup is required.\n' >&2
  else
    printf 'Reconciled creation ledger:\n' >&2
    jq -r '.[] | "#\(.number) | \(.title) | \(.url) | \(.bodyFile) | body_verified=\(.body_verified) | linked=\(.linked)"' "$LEDGER" >&2
    printf '\nCleanup commands:\n' >&2
    jq -r --arg repo "$REPO" '.[] | "gh issue delete \(.number) --repo \"\($repo)\" --yes"' "$LEDGER" >&2
    printf '\nThe operation did not complete. No automatic rollback was performed. Delete every issue in the ledger before invoking this skill again.\n' >&2
  fi
  exit 1
}

pages="$(gh api "repos/$REPO/issues/$PARENT_ISSUE/sub_issues" --paginate --slurp 2>&1)" || {
  printf 'Unable to query the pre-creation child baseline: %s\n' "$pages" >&2
  exit 1
}
baseline="$(printf '%s\n' "$pages" | normalize_pages 2>&1)" || {
  printf 'Unable to normalize the pre-creation child baseline: %s\n' "$baseline" >&2
  exit 1
}
jq -e 'type == "array" and all(.[]; type == "object")' <<<"$baseline" >/dev/null || {
  printf 'Pre-creation child baseline is not a flat issue array.\n' >&2
  exit 1
}
atomic_write "$BASELINE" "$baseline" || {
  printf 'Unable to persist pre-creation child baseline.\n' >&2
  exit 1
}
atomic_write "$LEDGER" '[]' || {
  printf 'Unable to initialize creation ledger.\n' >&2
  exit 1
}
atomic_write "$RESULT" '{"schemaVersion":1,"status":"in_progress","ledgerFile":"creation-ledger.json","operationError":null}' || {
  printf 'Unable to initialize stage result.\n' >&2
  exit 1
}

subsections=(
  '1. Implement Fibonacci with unit and isolated CLI coverage'
  '2. Add factorial and operation dispatch'
)
titles=(
  '1. Implement Fibonacci with unit and isolated CLI coverage'
  '2. Add factorial and operation dispatch'
)
body_files=(
  "$BODY_DIRECTORY/01-1-implement-fibonacci-body.md"
  "$BODY_DIRECTORY/02-2-add-factorial-dispatch-body.md"
)

for index in 0 1; do
  subsection="${subsections[$index]}"
  title="${titles[$index]}"
  body_file="${body_files[$index]}"
  relative_body="issue-bodies/$(basename "$body_file")"

  create_output="$(
    gh api "repos/$REPO/issues" \
      -X POST \
      -f title="$title" \
      -F "body=@$body_file" \
      --jq '{id,number,node_id,html_url,title}' 2>&1
  )" || reconcile_and_fail "create issue for $subsection" "$create_output"

  if ! issue_id="$(jq -er '.id | numbers' <<<"$create_output" 2>&1)" ||
     ! issue_number="$(jq -er '.number | numbers' <<<"$create_output" 2>&1)" ||
     ! issue_url="$(jq -er '.html_url | strings' <<<"$create_output" 2>&1)" ||
     ! actual_title="$(jq -er '.title | strings' <<<"$create_output" 2>&1)"; then
    reconcile_and_fail "parse create response for $subsection" "$create_output"
  fi

  ledger_updated="$(
    jq \
      --arg implementationSubsection "$subsection" \
      --arg bodyFile "$relative_body" \
      --argjson id "$issue_id" \
      --argjson number "$issue_number" \
      --arg title "$actual_title" \
      --arg url "$issue_url" \
      '. + [{
        implementationSubsection:$implementationSubsection,
        bodyFile:$bodyFile,
        id:$id,
        number:$number,
        title:$title,
        url:$url,
        body_verified:false,
        linked:false
      }]' \
      "$LEDGER" 2>&1
  )" || reconcile_and_fail "append issue #$issue_number to ledger" "$ledger_updated"
  atomic_write "$LEDGER" "$ledger_updated" ||
    reconcile_and_fail "persist issue #$issue_number in ledger" "atomic ledger write failed"

  verification_output="$(
    "$VERIFIER" \
      "$REPO" \
      "$issue_number" \
      "$body_file" \
      6 \
      5 \
      "$LOG_DIRECTORY/issue-$issue_number-body-verification-failure.json" 2>&1
  )" || reconcile_and_fail "verify body for issue #$issue_number" "$verification_output"
  update_ledger_flag "$issue_number" body_verified true ||
    reconcile_and_fail "persist body verification for issue #$issue_number" "ledger update failed"

  linked=false
  link_error=''
  for attempt in 1 2 3; do
    if link_output="$(
      printf '{"sub_issue_id": %s}' "$issue_id" |
        gh api "repos/$REPO/issues/$PARENT_ISSUE/sub_issues" -X POST --input - 2>&1
    )"; then
      linked=true
      break
    fi
    link_error="attempt $attempt: $link_output"
    [[ "$attempt" -eq 3 ]] || sleep 2
  done
  [[ "$linked" == true ]] ||
    reconcile_and_fail "link issue #$issue_number to parent #$PARENT_ISSUE" "$link_error"
  update_ledger_flag "$issue_number" linked true ||
    reconcile_and_fail "persist linked state for issue #$issue_number" "ledger update failed"
done

pages="$(gh api "repos/$REPO/issues/$PARENT_ISSUE/sub_issues" --paginate --slurp 2>&1)" ||
  reconcile_and_fail "query final parent children" "$pages"
final_children="$(printf '%s\n' "$pages" | normalize_pages 2>&1)" ||
  reconcile_and_fail "normalize final parent children" "$final_children"
jq -e 'type == "array" and all(.[]; type == "object")' <<<"$final_children" >/dev/null ||
  reconcile_and_fail "validate final parent children" "response is not a flat issue array"

baseline_count="$(jq 'length' "$BASELINE")"
ledger_count="$(jq 'length' "$LEDGER")"
final_count="$(jq 'length' <<<"$final_children")"
[[ "$final_count" -eq $((baseline_count + ledger_count)) ]] ||
  reconcile_and_fail "verify child count" "baseline=$baseline_count ledger=$ledger_count final=$final_count"

order_matches="$(
  jq -n \
    --argjson baseline "$(cat "$BASELINE")" \
    --argjson final "$final_children" \
    --argjson ledger "$(cat "$LEDGER")" \
    '([$final[] | select(.id as $id | all($baseline[]; .id != $id)) | .id] == [$ledger[].id])'
)"
[[ "$order_matches" == true ]] ||
  reconcile_and_fail "verify newly linked child order" "server order does not match plan order"

all_linked_once="$(
  jq -n \
    --argjson final "$final_children" \
    --argjson ledger "$(cat "$LEDGER")" \
    'all($ledger[]; . as $entry | ([$final[] | select(.id == $entry.id)] | length) == 1)'
)"
[[ "$all_linked_once" == true ]] ||
  reconcile_and_fail "verify each child is linked exactly once" "one or more ledger entries are absent or duplicated"

while IFS= read -r entry; do
  issue_number="$(jq -r '.number' <<<"$entry")"
  relative_body="$(jq -r '.bodyFile' <<<"$entry")"
  body_file="$LOG_DIRECTORY/$relative_body"
  final_verification="$(
    "$VERIFIER" \
      "$REPO" \
      "$issue_number" \
      "$body_file" \
      6 \
      5 \
      "$LOG_DIRECTORY/issue-$issue_number-body-verification-failure.json" 2>&1
  )" || reconcile_and_fail "final body verification for issue #$issue_number" "$final_verification"

  issue_state="$(
    gh api "repos/$REPO/issues/$issue_number" \
      --jq '{state,assigneeCount:(.assignees|length)}' 2>&1
  )" || reconcile_and_fail "query final state for issue #$issue_number" "$issue_state"
  jq -e '.state == "open" and .assigneeCount == 0' <<<"$issue_state" >/dev/null ||
    reconcile_and_fail "verify final state for issue #$issue_number" "$issue_state"
done < <(jq -c '.[]' "$LEDGER")

atomic_write "$RESULT" '{"schemaVersion":1,"status":"complete","ledgerFile":"creation-ledger.json","operationError":null}' ||
  reconcile_and_fail "persist complete stage result" "atomic result write failed"

printf 'Created and verified issues:\n'
jq -r '.[] | "\(.implementationSubsection) | #\(.number) | \(.title) | \(.url)"' "$LEDGER"
printf 'ORDERED_NUMBERS=%s\n' "$(jq -r '[.[].number | tostring] | join(",")' "$LEDGER")"
