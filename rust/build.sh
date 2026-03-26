#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Set Defaults
BUILD_TYPE="debug"
CARGO_ARGS=""
TARGET_DIR="debug"

# Parse Arguments
if [[ "$1" == "release" || "$1" == "--release" ]]; then
    BUILD_TYPE="release"
    CARGO_ARGS="--release"
    TARGET_DIR="release"
fi

echo "==================================================="
echo "Building Reia's Rust Backend in $BUILD_TYPE mode..."
echo "==================================================="

# Run Cargo Build
cargo build $CARGO_ARGS

# Determine OS for the correct file extension
OS_NAME=$(uname -s)
if [[ "$OS_NAME" == "Linux" ]]; then
    EXT="so"
elif [[ "$OS_NAME" == "Darwin" ]]; then
    EXT="dylib"
else
    echo "Unsupported OS: $OS_NAME"
    exit 1
fi

# Setup Output Directory
OUT_DIR="../godot/build/bin"
if [ ! -d "$OUT_DIR" ]; then
    echo "Creating directory: $OUT_DIR"
    mkdir -p "$OUT_DIR"
fi

# Copy and Rename the Shared Object
echo "Copying binary to $OUT_DIR/libreia_backend.$BUILD_TYPE.$EXT..."
cp "target/$TARGET_DIR/libreia_backend.$EXT" "$OUT_DIR/libreia_backend.$BUILD_TYPE.$EXT"

echo "Build and deployment complete!"
