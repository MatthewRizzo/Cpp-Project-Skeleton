#!/usr/bin/env bash
set -euo pipefail

# Usage:
#  scripts/format_code.bash          -> check formatting (non-destructive)
#  scripts/format_code.bash --apply  -> apply formatting in-place

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args: --apply and optional paths to check. If no paths provided,
# fall back to listing tracked files under src/ and tests/.
APPLY=false
PATHS=()
for a in "$@"; do
    if [ "$a" = "--apply" ]; then
        APPLY=true
    else
        PATHS+=("$a")
    fi
done

command -v clang-format >/dev/null 2>&1 || {
    echo "clang-format not found in PATH. Install clang-format to use this script. Try scripts/install_external_dependencies.bash" >&2
    exit 2
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
targets=()

# Optional config file to tweak behavior. If present, it can enable
# automatic detection of statement-like macros and add extra paths.
CONFIG="$repo_root/scripts/format_code.conf"
if [ -f "$CONFIG" ]; then
    # If requested, run the generator to populate StatementMacros in .clang-format
    if grep -E -q '^auto_detect_macros\s*=\s*true' "$CONFIG"; then
        if [ -f "$repo_root/scripts/generate_clang_statement_macros.py" ]; then
            python3 "$repo_root/scripts/generate_clang_statement_macros.py" || true
        fi
    fi
    # Allow config to provide extra comma-separated paths (relative to repo root)
    if grep -E -q '^paths\s*=' "$CONFIG"; then
        CONF_PATHS=$(sed -n 's/^paths\s*=\s*//p' "$CONFIG")
        IFS=',' read -r -a EXTRA_PATHS <<< "$CONF_PATHS"
        for p in "${EXTRA_PATHS[@]}"; do
            # Trim whitespace
            p="$(echo "$p" | sed -e 's/^\s*//' -e 's/\s*$//')"
            if [ -n "$p" ]; then
                PATHS+=("$p")
            fi
        done
    fi
fi

# If the user provided paths, expand them (directories -> matching files,
# files -> themselves). Otherwise list tracked files via git.
if [ ${#PATHS[@]} -gt 0 ]; then
    for p in "${PATHS[@]}"; do
        # Interpret paths relative to the repo root when not absolute
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
    if [ ${#files[@]} -eq 0 ]; then
        # No tracked files found (e.g., user hasn't committed). Fall back
        # to scanning the source and tests directories so formatting still
        # runs against local files. This ensures clang-format will use
        # the repository `.clang-format` for styling.
        while IFS= read -r f; do
            targets+=("$f")
        done < <(find "$repo_root/src" "$repo_root/tests" -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' -o -name '*.h' -o -name '*.hpp' -o -name '*.hh' \) -print 2>/dev/null || true)
    else
        for f in "${files[@]}"; do
            case "$f" in
                src/*|tests/*|test/*)
                    targets+=("$repo_root/$f")
                    ;;
            esac
        done
    fi
fi

if [ ${#targets[@]} -eq 0 ]; then
    if [ ${#PATHS[@]} -gt 0 ]; then
        echo "No matching files found for the provided paths:" >&2
        for p in "${PATHS[@]}"; do
            # show the resolved absolute path we tried
            if [ "${p:0:1}" != "/" ]; then
                echo " - $repo_root/$p" >&2
            else
                echo " - $p" >&2
            fi
        done
        echo "Ensure the paths exist and point to C/C++ source files." >&2
        exit 1
    else
        echo "No files under src/ or test(s)/ to format."
        exit 0
    fi
fi

unformatted=()
for f in "${targets[@]}"; do
    if [ "$APPLY" = true ]; then
        clang-format -style=file -i "$f"
    else
        if ! cmp -s <(clang-format -style=file "$f") "$f"; then
            unformatted+=("$f")
        fi
    fi
done

if [ "$APPLY" = false ]; then
    if [ ${#unformatted[@]} -ne 0 ]; then
        echo "The following files need formatting:"
        for u in "${unformatted[@]}"; do
            echo " - $u"
        done
        echo
        echo "Run: $script_dir/format_code.bash --apply  to reformat them." >&2
        exit 1
    else
        echo "All files are properly formatted."
    fi
else
    # If we applied formatting, report any modified files
    mapfile -t modified < <(git ls-files -m || true)
    if [ ${#modified[@]} -ne 0 ]; then
        echo "Reformatted files:"
        for m in "${modified[@]}"; do
            echo " - $m"
        done
        # stage modified files so the commit continues with formatted files
        git add -- "${modified[@]}" || true
    else
        echo "No changes after formatting."
    fi
fi

exit 0
