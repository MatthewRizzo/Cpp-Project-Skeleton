#!/usr/bin/env bash
set -euo pipefail

# Check dependencies using the common list in common_deps.bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common_deps.bash"

missing=()

# Ensure CMake is present and up-to-date via the dedicated check script.
if ! bash "$script_dir/check_cmake.bash"; then
    missing+=("cmake")
fi

check_unitest_header() {
    if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists UnitTest++; then
        return 0
    fi
    if [ -f "/usr/include/UnitTest++/UnitTest++.h" ] || [ -f "/usr/local/include/UnitTest++/UnitTest++.h" ]; then
        return 0
    fi
    return 1
}

check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

for pkg in "${PACKAGES[@]}"; do
    case "$pkg" in
        *unittest*|*UnitTest*|*unittestpp*)
            if ! check_unitest_header; then
                missing+=("$pkg")
            else
                echo "Found UnitTest++"
            fi
            ;;
        cmake)
            # cmake handled separately via check_cmake.bash; skip here.
            ;;
        build-essential|base-devel|gcc*|g++*|make)
            # check for basic build tools
            if ! check_command_exists g++ || ! check_command_exists make; then
                missing+=("$pkg")
            else
                echo "Found build tools (g++, make)"
            fi
            ;;
        *)
            # fallback: try to detect a binary with the same name
            if ! check_command_exists "$pkg"; then
                missing+=("$pkg")
            else
                echo "Found $pkg"
            fi
            ;;
    esac
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing dependencies:" >&2
    for m in "${missing[@]}"; do
        echo " - $m" >&2
    done
    echo
    echo "Run scripts/install_external_dependencies.bash to attempt installing these dependencies, or install them manually."
    exit 1
fi

echo "All required dependencies present."
exit 0
