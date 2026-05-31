#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENWRT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${OPENWRT_DIR}/../.." && pwd)"
OUTPUT_DIR="${OPENWRT_DIR}/dist"
BUILD_DIR="${OPENWRT_DIR}/build"
FILES_DIR="${OPENWRT_DIR}/files"

PACKAGE_NAME="fn-knock"
VERSION="1.7.0"
ARCH="x86_64"

echo "=== fn-knock OpenWRT IPK Builder ==="
echo "Package: ${PACKAGE_NAME}"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"

# Clean previous builds
rm -rf "${OUTPUT_DIR}" "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}" "${BUILD_DIR}"

# Copy files to build directory
echo "[1/5] Copying package files..."
cp -r "${FILES_DIR}/." "${BUILD_DIR}/"

# Build server-admin backend
echo "[2/5] Building server-admin backend..."
cd "${PROJECT_ROOT}"
npm run build 2>/dev/null || {
    echo "ERROR: Failed to build server-admin. Run 'npm run build' first."
    exit 1
}

# Copy built assets
echo "[3/5] Copying built assets..."
ADMIN_DIST="${PROJECT_ROOT}/apps/server-admin/dist"
AUTH_DIST="${PROJECT_ROOT}/apps/server-auth-view/dist"
VIEW_DIST="${PROJECT_ROOT}/apps/server-admin-view/dist"

if [ -d "${ADMIN_DIST}" ]; then
    mkdir -p "${BUILD_DIR}/usr/lib/fn-knock/server/server-admin"
    cp -r "${ADMIN_DIST}/." "${BUILD_DIR}/usr/lib/fn-knock/server/server-admin/"
    echo "  Copied server-admin dist"
fi

if [ -d "${AUTH_DIST}" ]; then
    mkdir -p "${BUILD_DIR}/usr/lib/fn-knock/server-auth-view/dist"
    cp -r "${AUTH_DIST}/." "${BUILD_DIR}/usr/lib/fn-knock/server-auth-view/dist/"
    echo "  Copied server-auth-view dist"
fi

if [ -d "${VIEW_DIST}" ]; then
    mkdir -p "${BUILD_DIR}/usr/lib/fn-knock/ui/www"
    cp -r "${VIEW_DIST}/." "${BUILD_DIR}/usr/lib/fn-knock/ui/www/"
    echo "  Copied server-admin-view dist"
fi

# Copy gateway binaries
echo "[4/5] Copying gateway binaries..."
GATEWAY_BIN_DIR="${BUILD_DIR}/usr/lib/fn-knock/server"
GATEWAY_SOURCE="${PROJECT_ROOT}/../Go-Reauth-Proxy"

if [ -d "${GATEWAY_SOURCE}" ]; then
    if [ -f "${GATEWAY_SOURCE}/go-reauth-proxy-linux-amd64" ]; then
        cp "${GATEWAY_SOURCE}/go-reauth-proxy-linux-amd64" "${GATEWAY_BIN_DIR}/"
        chmod +x "${GATEWAY_BIN_DIR}/go-reauth-proxy-linux-amd64"
        echo "  Copied amd64 gateway binary"
    fi
    if [ -f "${GATEWAY_SOURCE}/go-reauth-proxy-linux-arm64" ]; then
        cp "${GATEWAY_SOURCE}/go-reauth-proxy-linux-arm64" "${GATEWAY_BIN_DIR}/"
        chmod +x "${GATEWAY_BIN_DIR}/go-reauth-proxy-linux-arm64"
        echo "  Copied arm64 gateway binary"
    fi
else
    echo "  WARNING: Go-Reauth-Proxy source not found at ${GATEWAY_SOURCE}"
    echo "  Please copy gateway binaries manually to ${GATEWAY_BIN_DIR}/"
fi

# Copy Node.js runtime (if available)
echo "  Checking Node.js runtime..."
NODEJS_BUNDLE="${PROJECT_ROOT}/apps/fn-knock-openwrt/nodejs-bundle"
if [ -d "${NODEJS_BUNDLE}" ]; then
    cp -r "${NODEJS_BUNDLE}/." "${BUILD_DIR}/usr/lib/fn-knock/nodejs/"
    echo "  Copied bundled Node.js runtime"
else
    echo "  NOTE: No bundled Node.js found. User must install node package separately."
    echo "  Place Node.js in ${NODEJS_BUNDLE}/ to bundle it."
fi

# Calculate installed size
echo "[5/5] Calculating package size and building IPK..."
INSTALLED_SIZE=$(du -sk "${BUILD_DIR}" 2>/dev/null | cut -f1 || echo "0")

# Update control file with actual size
sed -i "s/Installed-Size: .*/Installed-Size: ${INSTALLED_SIZE}/" "${BUILD_DIR}/CONTROL/control"

# Build data.tar.gz
cd "${BUILD_DIR}"
find . -not -path './CONTROL/*' -not -path './CONTROL' | tar czf "${OUTPUT_DIR}/data.tar.gz" -T -

# Build control.tar.gz
cd "${BUILD_DIR}/CONTROL"
tar czf "${OUTPUT_DIR}/control.tar.gz" .

# Create debian-binary
echo "2.0" > "${OUTPUT_DIR}/debian-binary"

# Create final IPK
cd "${OUTPUT_DIR}"
ar r "${PACKAGE_NAME}_${VERSION}_${ARCH}.ipk" debian-binary control.tar.gz data.tar.gz

# Cleanup
rm -f "${OUTPUT_DIR}/debian-binary" "${OUTPUT_DIR}/control.tar.gz" "${OUTPUT_DIR}/data.tar.gz"

echo ""
echo "=== Build Complete ==="
echo "Output: ${OUTPUT_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.ipk"
echo "Size: $(du -h "${OUTPUT_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.ipk" | cut -f1)"
echo ""
echo "Installation:"
echo "  scp ${PACKAGE_NAME}_${VERSION}_${ARCH}.ipk root@<router-ip>:/tmp/"
echo "  ssh root@<router-ip> 'opkg install /tmp/${PACKAGE_NAME}_${VERSION}_${ARCH}.ipk'"
echo ""
echo "Usage:"
echo "  /etc/init.d/fn-knock start"
echo "  /etc/init.d/fn-knock stop"
echo "  /etc/init.d/fn-knock status"
echo "  /etc/init.d/fn-knock enable  (enable on boot)"
