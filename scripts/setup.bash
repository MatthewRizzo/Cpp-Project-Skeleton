#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

echo "Running repository setup..."

echo "1/3: Installing git hook (may require write access to .git/hooks)..."
bash "$script_dir/install_githook.bash"

echo "2/3: Checking CMake (may attempt to install/upgrade CMake)..."
bash "$script_dir/check_cmake.bash"

echo "3/3: Installing external dependencies (may require sudo)..."
bash "$script_dir/install_external_dependencies.bash"

echo "Setup complete."
exit 0
