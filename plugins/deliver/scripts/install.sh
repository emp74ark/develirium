#!/usr/bin/env bash
set -euo pipefail

plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="${1:-$PWD}"
agents_dir="$project_dir/.agents"

mkdir -p "$agents_dir"

copy_if_missing() {
  local source="$1" target="$2"
  if [ -e "$target" ]; then
    echo "kept    $target (already exists)"
  else
    cp "$source" "$target"
    echo "created $target"
  fi
}

add_ignore() {
  local line="$1" file="$project_dir/.gitignore"
  if [ -f "$file" ] && grep -qxF "$line" "$file"; then
    echo "kept    .gitignore has $line"
  else
    echo "$line" >> "$file"
    echo "added   $line to .gitignore"
  fi
}

copy_if_missing "$plugin_root/templates/profile.example.md" "$agents_dir/deliver.profile.md"
copy_if_missing "$plugin_root/templates/config.example.yml" "$agents_dir/config.yml"
add_ignore "/.worktrees/"
add_ignore "/.agents/config.local.yml"
