# Cpp Project Skeleton

Skeleton project template to facilitate easy-creation of new C++ repos.

Comes built in with:

* Cmake project structure for running compiling project and unit testing its libraries
* unit-test framework
* scripts to run
  * Static-analysis against changes in git or all files
  * Lint again changes in git or all files
  * Build the project
  * Check for and install external dependencies

## Building

Build (out-of-source):

* Simplify the build step with `scripts/build.sh`
* It accepts an optional build directory and any extra `cmake` arguments.

Run with `bash` or make it executable:

```bash
chmod +x scripts/build.bash
./scripts/build.bash

# run with explicit bash
bash scripts/build.bash [build-dir] [cmake-args...]

# example: disable tests
bash scripts/build.bash build -DBUILD_TESTING=OFF
```

### Manual Building

```bash
mkdir build
cd build
cmake -S .. -B .
cmake --build .
ctest --output-on-failure
```

To disable tests:

```bash
cmake -S .. -B . -DBUILD_TESTING=OFF
```

## Development Guidelines

Use these helper scripts during development to keep code formatted and checked.

### Setup Environment

Run the repository setup to prepare for development!

```bash
scripts/setup.bash
```

### Format `scripts/format_code.bash`

* Run the formatter check (non-destructive):

```bash
scripts/format_code.bash
```

* Apply formatting and stage changes:

```bash
scripts/format_code.bash --apply
```

### Static analysis: `scripts/run_static_analysis.bash`

* Run static analysis (uses `clang-tidy` when available, falls back to `cppcheck`):

```bash
scripts/run_static_analysis.bash [build-dir]
```

* Run and apply fixes with `clang-tidy` (if supported):

```bash
scripts/run_static_analysis.bash [build-dir] --fix
```

### Install Git hook: `scripts/install_githook.bash`

* Create a symlink from `.git/hooks/pre-commit` to the repository tracked
`.githooks/pre-commit` so the pre-commit hook is consistent for all clones:

```bash
scripts/install_githook.bash
```

* `scripts/build.bash` prints a warning if the hook symlink is not installed.
