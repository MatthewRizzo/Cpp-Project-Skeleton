#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/run_static_analysis.bash [build-dir] [--fix]
#
# Runs static analysis using `clang-tidy` if available, otherwise falls back
# to `cppcheck` when possible.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

# Parse args: optional build-dir (if an existing dir passed first), optional
# --fix flag, and optional list of paths to analyze. If no paths provided,
# fall back to tracked files via git.
BUILD_DIR=build
FIX=false
PATHS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --fix)
            FIX=true
            shift
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            shift
            ;;
        *)
            if [ "$BUILD_DIR" = "build" ] && [ -d "$1" ]; then
                BUILD_DIR="$1"
                shift
            else
                PATHS+=("$1")
                shift
            fi
            ;;
    esac
done

if command -v clang-tidy >/dev/null 2>&1; then
    analyzer=clang-tidy
elif command -v cppcheck >/dev/null 2>&1; then
    analyzer=cppcheck
else
    echo "No supported static analysis tool found (clang-tidy or cppcheck)." >&2
    exit 2
fi

echo "Using analyzer: $analyzer"

targets=()
if [ ${#PATHS[@]} -gt 0 ]; then
    # Expand provided paths (directories -> matching files)
    for p in "${PATHS[@]}"; do
        if [ "${p:0:1}" != "/" ]; then
            p="$repo_root/$p"
        fi
        if [ -d "$p" ]; then
            while IFS= read -r f; do
                targets+=("$f")
            done < <(find "$p" -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' -o -name '*.h' -o -name '*.hpp' -o -name '*.hh' \) -print)
        elif [ -f "$p" ]; then
            targets+=("$p")
        fi
    done
else
    # No explicit paths -> use tracked files under repo
    mapfile -t files < <(git -C "$repo_root" ls-files -- '*.c' '*.cpp' '*.cc' '*.cxx' '*.h' '*.hpp' '*.hh' 2>/dev/null || true)
    for f in "${files[@]}"; do
        case "$f" in
            src/*|tests/*|test/*)
                targets+=("$repo_root/$f")
                ;;
        esac
    done
fi

if [ ${#targets[@]} -eq 0 ]; then
    echo "No source files under src/ or tests/ to analyze."
    exit 0
fi

if [ "$analyzer" = "clang-tidy" ]; then
    if [ ! -f "${BUILD_DIR}/compile_commands.json" ]; then
        echo "Warning: ${BUILD_DIR}/compile_commands.json not found; clang-tidy may not have correct compile flags." >&2
    fi
    for f in "${targets[@]}"; do
        echo "Checking $f with clang-tidy..."
        if [ "$FIX" = true ]; then
            clang-tidy -p "$BUILD_DIR" --fix "$f" || true
        else
            clang-tidy -p "$BUILD_DIR" "$f" -- || true
        fi
    done
    echo "clang-tidy run complete."
else
    # cppcheck: run with common options
    cppcheck --enable=all --inconclusive --std=c++17 --force "${targets[@]}" || true
    echo "cppcheck run complete."
fi

exit 0
