#!/usr/bin/env bash
set -euo pipefail

# Resolve the skill root (one level up from scripts/)
skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Merge provider sections from the template into an existing config file.
# If the config doesn't exist yet, copy the template directly.
# If it exists, adds any missing provider blocks (e.g. junie, claude) without
# overwriting the existing settings.
merge_config() {
  local template="$1" target="$2"
  if [ ! -f "$template" ]; then
    echo "skip    template not found: $template"
    return
  fi
  if [ ! -e "$target" ]; then
    cp "$template" "$target"
    echo "created $target"
    return
  fi

  # Extract provider names from the template (keys directly under "providers:").
  local providers
  providers=$(awk '/^providers:/{found=1; next} found && /^  [a-z]+:/{sub(/:$/,"",$0); print substr($0,3)} found && /^[^ ]/{found=0}' "$template" | sort -u)

  local changed=false
  for provider in $providers; do
    [ -z "$provider" ] && continue
    # Check if this provider block already exists in the target.
    if ! grep -q "^  ${provider}:" "$target"; then
      # Extract the block for this provider from the template.
      local block
      block=$(awk -v prov="$provider" '
        /^providers:/ { in_providers=1; next }
        in_providers && $0 ~ "^  " prov ":" { found=1; print; next }
        in_providers && found && $0 ~ "^  [a-z]" && $0 !~ "^  " prov ":" { found=0; next }
        in_providers && found && /^  / { print; next }
        in_providers && found && !/^  / { found=0; next }
      ' "$template")
      if [ -n "$block" ]; then
        # Find the line number of the "providers:" key in the target.
        local prov_line
        prov_line=$(grep -n '^providers:' "$target" | head -1 | cut -d: -f1)
        if [ -n "$prov_line" ]; then
          # Write block to a temp file and use sed 'r' to insert it safely.
          local tmp_block
          tmp_block=$(mktemp)
          printf '%s\n' "$block" > "$tmp_block"
          sed -i "${prov_line}r $tmp_block" "$target"
          rm -f "$tmp_block"
          echo "added   providers.${provider} section to $target"
          changed=true
        fi
      fi
    fi
  done

  if [ "$changed" = false ]; then
    echo "kept    $target (all provider sections present)"
  fi
}

copy_if_missing "$skill_root/references/profile.example.md" "$agents_dir/deliver.profile.md"
merge_config "$skill_root/references/config.example.yml" "$agents_dir/config.yml"
add_ignore "/.worktrees/"
add_ignore "/.agents/config.local.yml"
