#!/bin/bash

# Usage: ./build.sh [windows|linux|mac|all]
set -e

declare -A targets
targets[windows]="x86_64-pc-windows-msvc"
targets[linux]="x86_64-unknown-linux-gnu"
targets[mac]="x86_64-apple-darwin"

build_target() {
    local os=$1
    local target=${targets[$os]}
    if [[ -z "$target" ]]; then
        echo "Unknown OS: $os"
        exit 1
    fi
    echo "Building for $os ($target)..."
    cargo build --release --target "$target"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [windows|linux|mac|all]"
    exit 1
fi

if [[ "$1" == "all" ]]; then
    for os in "${!targets[@]}"; do
        build_target "$os"
    done
else
    for os in "$@"; do
        build_target "$os"
    done
fi
