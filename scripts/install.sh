#!/usr/bin/env bash
set -euo pipefail

# Install the deliver plugin for an agent target.
# Usage: scripts/install.sh antigravity

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-}"

case "$target" in
  antigravity)
    if command -v agy >/dev/null 2>&1; then
      agy plugin install "$repo_root"
    else
      # Fallback: stage the plugin where the Antigravity CLI keeps global plugins.
      dest_dir="${ANTIGRAVITY_PLUGINS_DIR:-$HOME/.gemini/config/plugins}/deliver"
      mkdir -p "$dest_dir"
      cp -R "$repo_root/.antigravity-plugin" "$repo_root/skills" "$repo_root/agents" "$dest_dir/"
      echo "installed $repo_root -> $dest_dir"
    fi
    echo "next: in your project run 'bash <plugin>/skills/deliver/scripts/install.sh' to create .agents/ files"
    ;;
  *)
    echo "usage: $0 antigravity" >&2
    exit 1
    ;;
esac
