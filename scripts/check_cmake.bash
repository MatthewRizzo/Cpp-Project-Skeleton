#!/usr/bin/env bash
set -euo pipefail

# Ensure cmake >= 3.5 is available. If not, try to install a newer CMake.
required_major=3
required_minor=5

version_ge() {
    # compare two semantic versions, return 0 if $1 >= $2
    # usage: version_ge "3.28.3" "3.5"
    local IFS=.
    local -a va vb
    read -r -a va <<< "$1"
    read -r -a vb <<< "$2"
    for i in 0 1 2; do
        local ai=${va[i]:-0}
        local bi=${vb[i]:-0}
        # avoid octal interpretation
        ai=${ai##+(0)}
        bi=${bi##+(0)}
        ai=${ai:-0}
        bi=${bi:-0}
        if ((10#${ai} > 10#${bi})); then
            return 0
        elif ((10#${ai} < 10#${bi})); then
            return 1
        fi
    done
    return 0
}

check_cmake_version() {
  if ! command -v cmake >/dev/null 2>&1; then
    return 1
  fi
  ver=$(cmake --version 2>/dev/null | head -n1 | sed -E 's/.* ([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/')
  if [ -z "$ver" ]; then
    return 1
  fi
  if version_ge "$ver" "${required_major}.${required_minor}"; then
    return 0
  fi
  return 1
}

if check_cmake_version; then
  echo "CMake is already >= ${required_major}.${required_minor}: $(cmake --version | head -n1)"
  exit 0
fi

echo "CMake < ${required_major}.${required_minor} or missing — attempting to install a newer CMake..."

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian)
      echo "Adding Kitware APT repository and installing latest CMake..."
      sudo apt-get install -y apt-transport-https ca-certificates gnupg curl lsb-release
      curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | sudo gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
      sudo apt update
      sudo apt install -y cmake
      ;;
    *)
      echo "Attempting to download a recent CMake binary (x86_64)."
      tmpd=$(mktemp -d)
      cmake_ver="3.28.3"
      cmake_pkg="cmake-${cmake_ver}-linux-x86_64.tar.gz"
      url="https://github.com/Kitware/CMake/releases/download/v${cmake_ver}/${cmake_pkg}"
      echo "Downloading ${url}..."
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$tmpd/$cmake_pkg"
      elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmpd/$cmake_pkg" "$url"
      else
        echo "Neither curl nor wget available to download CMake binary. Please install CMake manually." >&2
        exit 1
      fi
      echo "Extracting and installing to /opt/cmake-${cmake_ver} (requires sudo)..."
      sudo tar -xzf "$tmpd/$cmake_pkg" -C /opt
      # The tarball contains a folder like cmake-3.28.3-linux-x86_64
      sudo ln -sf "/opt/cmake-${cmake_ver}-linux-x86_64/bin/cmake" /usr/local/bin/cmake
      rm -rf "$tmpd"
      ;;
  esac
else
  echo "Could not detect distribution; please install CMake >= ${required_major}.${required_minor} manually." >&2
  exit 1
fi

if check_cmake_version; then
  echo "Successfully installed/updated CMake to meet version requirements."
  exit 0
else
  echo "Failed to install a sufficient CMake version. Please install CMake >= ${required_major}.${required_minor} manually." >&2
  exit 1
fi
