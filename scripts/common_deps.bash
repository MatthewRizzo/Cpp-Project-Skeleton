#!/usr/bin/env bash
# Defines the package lists for supported distributions and exposes a
# `PACKAGES` array appropriate for the current host. Source this file
# from other scripts.

set -euo pipefail

# Default empty
PACKAGES=()

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            # Debian/Ubuntu package names (cmake handled separately)
            PACKAGES=(build-essential clang-format clang-tidy)
            ;;
        fedora)
            PACKAGES=(make gcc-c++ clang-tools-extra)
            ;;
        centos|rhel)
            PACKAGES=(make gcc-c++ clang-tools-extra)
            ;;
        arch)
            PACKAGES=(base-devel clang clang-tools)
            ;;
        *)
            # Fallback: no distro-specific packages
            PACKAGES=()
            ;;
    esac
else
    PACKAGES=()
fi

export PACKAGES
