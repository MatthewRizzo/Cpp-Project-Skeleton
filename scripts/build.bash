#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/build.bash [build-dir] [cmake-args...]
# Example: ./scripts/build.bash build -DBUILD_TESTING=OFF

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 
# Warn if the repository pre-commit symlink isn't installed
repo_root="$(cd "$script_dir/.." && pwd)"
expected_hook="$repo_root/.githooks/pre-commit"
installed_hook="$repo_root/.git/hooks/pre-commit"
if [ ! -L "$installed_hook" ]; then
  echo "Warning: pre-commit hook symlink not installed. Run '$script_dir/install_githook.bash' to install." >&2
fi

# ensure cmake is installed before proceeding
bash "$script_dir/check_cmake.bash"

# ensure external dependencies are present (UnitTest++ etc.)
bash "$script_dir/check_dependencies.bash" || {
  echo "Missing dependencies. Attempting to install..."
  bash "$script_dir/install_external_dependencies.bash"
  # re-run the check after attempting install
  bash "$script_dir/check_dependencies.bash"
}

# run format checker before building
bash "$script_dir/format_code.bash" --apply || {
  echo "Code formatting issues detected. Run '$script_dir/format_code.bash --apply' to fix." >&2
  exit 1
}

BUILD_DIR=${1:-build}
shift || true

mkdir -p "$BUILD_DIR"

cmake_args=("$@")

# If the user didn't pass an explicit CMAKE_EXPORT_COMPILE_COMMANDS setting,
# default to enabling compile_commands.json for editor tooling.
found_export=false
for a in "${cmake_args[@]}"; do
  case "$a" in
    *CMAKE_EXPORT_COMPILE_COMMANDS*)
      found_export=true
      break
      ;;
  esac
done
if [ "$found_export" = false ]; then
  cmake_args+=("-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
fi

# If the user didn't supply a CMake policy minimum, add a safe default so
# older external projects that call `cmake_minimum_required(VERSION X.Y)`
# with X.Y < 3.5 don't break newer CMake versions. Users can override by
# passing their own -DCMAKE_POLICY_VERSION_MINIMUM or -DCMAKE_POLICY_VERSION.
found_policy=false
for a in "${cmake_args[@]}"; do
  case "$a" in
    *CMAKE_POLICY_VERSION_MINIMUM*|*CMAKE_POLICY_VERSION*)
      found_policy=true
      break
      ;;
  esac
done
if [ "$found_policy" = false ]; then
  cmake_args+=("-DCMAKE_POLICY_VERSION_MINIMUM=3.5")
fi

cmake -S . -B "$BUILD_DIR" "${cmake_args[@]}"
cmake --build "$BUILD_DIR"

# run tests if they were configured
ctest --test-dir "$BUILD_DIR" --output-on-failure || true
