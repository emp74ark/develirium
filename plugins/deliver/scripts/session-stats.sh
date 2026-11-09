#!/usr/bin/env bash
set -euo pipefail

session="${1:?usage: session-stats.sh <session-id | session-name>}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_file="$script_dir/../skills/run/SKILL.md"
agents_dir="$script_dir/../agents"
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Session stats unavailable: jq is not installed."
  exit 0
fi

main=$(find "$config_dir/projects" -maxdepth 2 -name "$session.jsonl" -print -quit)
if [ -z "$main" ]; then
  title_file=$(find "$config_dir/projects" -maxdepth 3 -name custom-title.json -exec jq -r --arg name "$session" 'select(.customTitle == $name) | input_filename' {} + 2>/dev/null | xargs -r ls -t 2>/dev/null | head -1)
  if [ -n "$title_file" ]; then
    main="$(dirname "$title_file").jsonl"
  fi
fi
if [ -z "$main" ] || [ ! -f "$main" ]; then
  echo "Session stats unavailable: no transcript for session $session."
  exit 0
fi

subagent_dir="${main%.jsonl}/subagents"

frontmatter_value() {
  local file="$1" key="$2"
  if [ -f "$file" ]; then
    sed -n '2,/^---$/p' "$file" | sed -n "s/^$key: *//p" | head -1
  fi
}

transcript_stats() {
  local agent="$1" task="$2" transcript="$3" definition="$4"
  jq -s -c --arg agent "$agent" --arg task "$task" \
    --arg expected_model "$(frontmatter_value "$definition" model | sed 's/^inherit$//')" \
    --arg expected_effort "$(frontmatter_value "$definition" effort)" '
    def epoch: sub("\\.[0-9]+Z$"; "Z") | fromdate;
    [ .[] | select(.type == "assistant" and .message.usage != null) ]
    | (map(.timestamp) | sort) as $ts
    | group_by(.message.id) | map(last)
    | {
        agent: $agent,
        task: $task,
        expected_model: $expected_model,
        expected_effort: (if $expected_effort == "" then "inherit" else $expected_effort end),
        calls: map({
          model: .message.model,
          effort: (.effort // ""),
          input: (.message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)),
          output: (.message.usage.output_tokens // 0)
        }),
        seconds: (if ($ts | length) > 1 then ($ts[-1] | epoch) - ($ts[0] | epoch) else 0 end)
      }
  ' "$transcript"
}

{
  transcript_stats "orchestrator" "/deliver:run" "$main" "$skill_file"
  if [ -d "$subagent_dir" ]; then
    for meta in $(ls -tr "$subagent_dir"/*.meta.json 2>/dev/null); do
      agent=$(jq -r '.agentType // "unknown"' "$meta")
      transcript_stats "$agent" "$(jq -r '.description // ""' "$meta")" "${meta%.meta.json}.jsonl" "$agents_dir/${agent##*:}.md"
    done
  fi
} | jq -s -r '
  def fmt: tostring | if length > 3 then (.[:-3] | fmt) + "," + .[-3:] else . end;
  def dur: "\(. / 60 | floor)m \(. % 60)s";
  def models: [.calls[].model] | unique;
  def efforts: [.calls[].effort | select(. != "")] | unique;
  def model_ok: .expected_model as $m | $m == "" or (models | all(contains($m)));
  def effort_ok: .expected_effort as $e | $e == "inherit" or (efforts | all(. == $e));
  def mark: if . then "yes" else "**no**" end;
  def row: "| \(.agent) | \(.task) | \(.expected_model) / \(.expected_effort) | \(models | join(", ")) / \(efforts | join(", ")) | \(model_ok and effort_ok | mark) | \(.calls | length) | \(.calls | map(.input) | add // 0 | fmt) | \(.calls | map(.output) | add // 0 | fmt) | \(.seconds | dur) |";
  "| Agent | Task | Expected model / effort | Used model / effort | Match | API calls | Input tokens | Output tokens | Duration |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  (.[] | row),
  "| **Total** | | | | | \(map(.calls | length) | add) | \(map(.calls[].input) | add | fmt) | \(map(.calls[].output) | add | fmt) | |",
  "",
  "Tokens by model:",
  ([.[].calls[]] | group_by(.model) | .[] | "- \(.[0].model): \(length) calls, \(map(.input) | add | fmt) input, \(map(.output) | add | fmt) output"),
  "",
  "Input tokens include cache reads and cache writes."
'
