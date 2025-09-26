#!/bin/bash
targets=(
    x86_64-pc-windows-msvc
    x86_64-unknown-linux-gnu
    x86_64-apple-darwin
)

for target in "${targets[@]}"; do
    echo "Building for $target..."
    cargo build --release --target $target
done
