#!/bin/bash
set -euo pipefail

# Cross-compiles the project's functions for the Dandelion platform using the
# Dandelion SDK (dsdk) compiler. Fetches the compiler if none is given (-c).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$DIR")"
readonly color_cyan="\033[96m"
readonly color_red="\033[91m"
readonly color_bold="\033[1m"
readonly color_reset="\033[0m"

function msg() {
  local col=${2:-$color_cyan}
  echo -e "${col}${color_bold}${1}${color_reset}"
}

# configuration
build_dir="build"
build_type="Release"
dsdk_compiler_path=""
platform="kvm"
dsdk_version="latest"
tune_arch=""
while getopts 'b:r:c:p:v:t:' flag; do
  case "${flag}" in
    b) build_dir="${OPTARG}" ;;
    r) build_type="${OPTARG}" ;;
    c) dsdk_compiler_path="${OPTARG}" ;;
    p) platform="${OPTARG}" ;;
    v) dsdk_version="${OPTARG}" ;;
    t) tune_arch="${OPTARG}" ;;
    *) printf "Usage: %s [-b build_dir] [-r Debug|Release] [-c dsdk_compiler_path] [-p debug|kvm|mmu_linux] [-v latest|experimental] [-t cpu_arch]\n" "$0"
       exit 1 ;;
  esac
done
printf "Build configuration:\n build_dir=%s\n build_type=%s\n dsdk_compiler_path=%s\n platform=%s\n dsdk_version=%s\n tune_arch=%s\n" \
  "$build_dir" "$build_type" "$dsdk_compiler_path" "$platform" "$dsdk_version" "$tune_arch"

# create build folder (relative paths are resolved against the project root)
cd "$PROJECT_DIR"
if [ -d "$build_dir" ]; then
  msg "Build folder '$build_dir' already exists!" $color_red
  exit 1
fi
mkdir -p "$build_dir"
pushd "$build_dir" > /dev/null

# configure dandelion sdk compiler
if [ -z "$dsdk_compiler_path" ]; then
  "$DIR"/setup_dsdk.sh -i _dsdk -p "${platform}" -v "${dsdk_version}"
  dsdk_compiler_path=$(pwd)/_dsdk
else
  dsdk_compiler_path="$(cd "$dsdk_compiler_path" && pwd)"
  msg "Using manually specified compiler under '${dsdk_compiler_path}'"
fi
arch=$(uname -m)
export CC=${dsdk_compiler_path}/${arch}-unknown-dandelion-clang
export CXX=${dsdk_compiler_path}/${arch}-unknown-dandelion-clang++

# (optionally) set tuning compiler flags
if [ -n "$tune_arch" ]; then
  sed -i "s/^#\?-march=.*/-march=$tune_arch/" "${CC}.cfg"
  sed -i "s/^#\?-mtune=.*/-mtune=$tune_arch/" "${CC}.cfg"
fi

# configure and build
if type ninja &> /dev/null; then
  cmake "$PROJECT_DIR" -GNinja -DCMAKE_BUILD_TYPE="${build_type}"
  ninja
else
  cmake "$PROJECT_DIR" -DCMAKE_BUILD_TYPE="${build_type}"
  make -j"$(nproc)"
fi

popd > /dev/null # $build_dir
msg "Dandelion function binaries are in '${build_dir}/bin/'."
