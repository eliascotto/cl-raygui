#!/bin/bash
# Native macOS build adapted from raygui's README (Mac / clang / Homebrew).
set -euo pipefail

if [ "$(uname -s)" != Darwin ]; then
    printf '%s\n' 'This build script requires macOS. Use CMake on other platforms.' >&2
    exit 1
fi

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

# Homebrew may not be on PATH when invoked from an editor or Lisp IDE.
for brew_bin in /opt/homebrew/bin /usr/local/bin; do
    if [ -x "$brew_bin/pkg-config" ]; then
        export PATH="$brew_bin:$PATH"
        break
    fi
done

if ! command -v pkg-config >/dev/null || ! pkg-config --exists raylib; then
    printf '%s\n' 'Install the macOS dependencies with: brew install raylib pkgconf' >&2
    exit 1
fi

mkdir -p build
# Keep the pkg-config arguments in an array instead of evaluating shell text.
read -r -a raylib_flags <<< "$(pkg-config --cflags --libs raylib)"
"${CC:-clang}" -std=c99 -O2 -shared -fPIC -DBUILD_LIBTYPE_SHARED \
    -Ivendor src/raygui.c -o build/libraygui.dylib \
    -framework OpenGL -lm -lpthread -ldl "${raylib_flags[@]}"

printf '%s\n' "Built $project_dir/build/libraygui.dylib"
