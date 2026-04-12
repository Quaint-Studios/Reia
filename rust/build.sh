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
ARCH_NAME=$(uname -m)

if [[ "$OS_NAME" == "Linux" ]]; then
    EXT="so"
    OS_ID="linux"
elif [[ "$OS_NAME" == "Darwin" ]]; then
    EXT="dylib"
    OS_ID="macos"
else
    echo "Unsupported OS: $OS_NAME"
    exit 1
fi

if [[ "$ARCH_NAME" == "x86_64" ]]; then
    ARCH_ID="x86_64"
elif [[ "$ARCH_NAME" == "arm64" || "$ARCH_NAME" == "aarch64" ]]; then
    ARCH_ID="arm64"
else
    ARCH_ID="$ARCH_NAME"
fi

# For local macOS testing, pretend the binary is 'universal' so it 
# matches the reia.gdextension configuration, allowing Godot to load it.
if [[ "$OS_ID" == "macos" ]]; then
    ARCH_ID="universal"
fi

FINAL_FILENAME="libreia_backend.${OS_ID}.${BUILD_TYPE}.${ARCH_ID}.${EXT}"

# Setup Output Directory
OUT_DIR="../godot/build/bin"
if [ ! -d "$OUT_DIR" ]; then
    echo "Creating directory: $OUT_DIR"
    mkdir -p "$OUT_DIR"
fi

# Copy and Rename the Shared Object
echo "Copying binary to $OUT_DIR/$FINAL_FILENAME..."
cp "target/$TARGET_DIR/libreia_backend.$EXT" "$OUT_DIR/$FINAL_FILENAME"

echo "Build and deployment complete!"
