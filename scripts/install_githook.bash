#!/usr/bin/env bash
set -euo pipefail

# Installs a symlink from .git/hooks/pre-commit to the source-controlled
# .githooks/pre-commit file in the repo root.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
githook_src="$repo_root/.githooks/pre-commit"
git_hook_dir="$repo_root/.git/hooks"
git_hook_target="$git_hook_dir/pre-commit"

if [ ! -d "$repo_root/.git" ]; then
    echo "Not a git repository (no .git directory found)." >&2
    exit 1
fi

if [ ! -f "$githook_src" ]; then
    echo "Source hook not found: $githook_src" >&2
    exit 1
fi

mkdir -p "$git_hook_dir"

if [ -L "$git_hook_target" ]; then
    current=$(readlink -f "$git_hook_target")
    desired=$(readlink -f "$githook_src")
    if [ "$current" = "$desired" ]; then
        echo "Pre-commit hook symlink already installed."
        exit 0
    else
        echo "Replacing existing pre-commit symlink." 
        rm -f "$git_hook_target"
    fi
fi

if [ -e "$git_hook_target" ] && [ ! -L "$git_hook_target" ]; then
    ts=$(date +%s)
    backup="$git_hook_target.bak.$ts"
    echo "Backing up existing hook to $backup"
    mv "$git_hook_target" "$backup"
fi

ln -s "$githook_src" "$git_hook_target"
chmod +x "$githook_src"

echo "Installed pre-commit hook symlink: $git_hook_target -> $githook_src"
exit 0
