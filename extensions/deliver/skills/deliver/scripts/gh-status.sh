#!/usr/bin/env bash
if ! command -v gh >/dev/null 2>&1; then echo "gh: not installed"
elif ! gh auth status >/dev/null 2>&1; then echo "gh: not authenticated"
elif ! repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null); then echo "gh: no GitHub repository for this checkout"
else echo "gh: ready ($repo)"
fi
