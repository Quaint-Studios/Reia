#!bin/bash

# Inputs
DEFAULT_VERSION="4.2.1-stable"
VERSION=${1:-$DEFAULT_VERSION}

# Checksums
declare -rA checksums=(["4.2.1-stable"]="86311a9e75b7445eb4215312e604df1f69c72d4641af3e67049e30356ae37660")

# Variables
URL="https://github.com/godotengine/godot/releases/download"
PREFIX="Godot_v"
SUFFIX="_linux.x86_64"
EXT=".zip"
FILE=$PREFIX$VERSION$SUFFIX


# Get Files
wget ${URL}/${VERSION}/${FILE}${EXT}

# Generate Checksum for new version of Godot if you need to add it above.
# sha256sum ./Godot_v${VERSION}_linux.x86_64.zip


# Validate Checksum
CHECKSUM256=${checksums[$VERSION]}
echo $CHECKSUM256 $FILE$EXT  | sha256sum -c --quiet >/dev/null 2>&1
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo -n "PASS "
else
    echo -n "FAIL "
    exit 0
fi

# Unzip
apt install unzip -y
unzip ./$FILE$EXT -d ../../ # Extract to Reia's directory

# Run Godot and build
./$FILE --path ./project.godot --export "linux_server" .builds/server/Reia

exit 1
