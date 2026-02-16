#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common_deps.bash"

echo "Installing external dependencies (may require sudo)..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y "${PACKAGES[@]}"
            ;;
        fedora)
            sudo dnf install -y "${PACKAGES[@]}"
            ;;
        centos|rhel)
            sudo yum install -y epel-release
            sudo yum install -y "${PACKAGES[@]}"
            ;;
        arch)
            sudo pacman -Syu --noconfirm "${PACKAGES[@]}"
            ;;
        *)
            echo "Automatic install not supported for $ID. See https://cmake.org/install/ and https://unittest-cpp.github.io/ for manual installation instructions."
            exit 1
            ;;
    esac
else
    echo "Unknown distribution; please install the following packages manually: ${PACKAGES[*]}"
    exit 1
fi

echo "Dependencies installed (if supported by distribution)."
exit 0
