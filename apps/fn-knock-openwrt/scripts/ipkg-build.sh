#!/bin/bash
# ipkg-build - Create an IPK package (OpenWRT standard format)
# Usage: ipkg-build <pkg_dir> [dest_dir]

set -e

PKG_DIR="${1:-.}"
DEST_DIR="${2:-.}"

if [ ! -d "$PKG_DIR" ]; then
    echo "Error: $PKG_DIR is not a directory"
    exit 1
fi

# Read control file
CONTROL_FILE="$PKG_DIR/CONTROL/control"
if [ ! -f "$CONTROL_FILE" ]; then
    echo "Error: CONTROL/control not found"
    exit 1
fi

PKG_NAME=$(grep '^Package:' "$CONTROL_FILE" | cut -d' ' -f2-)
PKG_VERSION=$(grep '^Version:' "$CONTROL_FILE" | cut -d' ' -f2-)

if [ -z "$PKG_NAME" ] || [ -z "$PKG_VERSION" ]; then
    echo "Error: Package name or version not found in CONTROL/control"
    exit 1
fi

IPK_NAME="${PKG_NAME}_${PKG_VERSION}_x86_64.ipk"

echo "Building $IPK_NAME..."

# Create control.tar.gz
cd "$PKG_DIR"
tar czf control.tar.gz CONTROL/

# Create data.tar.gz
find . -not -path './CONTROL' -not -path './CONTROL/*' -not -name 'control.tar.gz' | tar czf data.tar.gz -T -

# Create debian-binary
echo "2.0" > debian-binary

# Create IPK using ar
ar r "$DEST_DIR/$IPK_NAME" debian-binary control.tar.gz data.tar.gz

# Cleanup
rm -f debian-binary control.tar.gz data.tar.gz

echo "Package $DEST_DIR/$IPK_NAME built successfully."
