#!/bin/bash
set -e

SRCDIR="/mnt/d/用户文件/桌面/code/new_repo/fn-knock-turborepo"
BUILDDIR="/tmp/fn-knock-build-$$"
OUTDIR="$SRCDIR/apps/fn-knock-openwrt/dist"

echo "=== Building fn-knock IPK ==="
echo "Build dir: $BUILDDIR"

# Clean
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"/{CONTROL,etc/init.d,etc/config,etc/fn-knock}
mkdir -p "$BUILDDIR"/usr/lib/fn-knock/server/server-admin
mkdir -p "$BUILDDIR"/usr/lib/fn-knock/server-auth-view/dist
mkdir -p "$BUILDDIR"/usr/lib/fn-knock/ui/www
mkdir -p "$BUILDDIR"/usr/lib/lua/luci/controller
mkdir -p "$BUILDDIR"/usr/lib/lua/luci/view/fn-knock
mkdir -p "$BUILDDIR"/usr/lib/lua/luci/model/cbi/fn-knock
mkdir -p "$BUILDDIR"/www/cgi-bin

echo "[1/4] Copying control files..."
cp "$SRCDIR/apps/fn-knock-openwrt/files/CONTROL/"* "$BUILDDIR/CONTROL/"

echo "[2/4] Copying config and init scripts..."
cp "$SRCDIR/apps/fn-knock-openwrt/files/etc/init.d/fn-knock" "$BUILDDIR/etc/init.d/"
cp "$SRCDIR/apps/fn-knock-openwrt/files/etc/config/fn-knock" "$BUILDDIR/etc/config/"

echo "[3/4] Copying LuCI files..."
cp "$SRCDIR/apps/fn-knock-openwrt/files/usr/lib/lua/luci/controller/fn-knock.lua" "$BUILDDIR/usr/lib/lua/luci/controller/"
cp "$SRCDIR/apps/fn-knock-openwrt/files/usr/lib/lua/luci/view/fn-knock/status.htm" "$BUILDDIR/usr/lib/lua/luci/view/fn-knock/"
cp "$SRCDIR/apps/fn-knock-openwrt/files/usr/lib/lua/luci/model/cbi/fn-knock/settings.lua" "$BUILDDIR/usr/lib/lua/luci/model/cbi/fn-knock/"

echo "[4/4] Copying binaries and dist..."
# Gateway binary
cp -r "$SRCDIR/apps/fn-knock-openwrt/build/usr/lib/fn-knock/server/go-reauth-proxy-linux-amd64" "$BUILDDIR/usr/lib/fn-knock/server/go-reauth-proxy-linux-amd64"
chmod 755 "$BUILDDIR/usr/lib/fn-knock/server/go-reauth-proxy-linux-amd64"

# Node.js backend (cp -r does NOT preserve hard links, each file becomes independent)
cp -r "$SRCDIR/apps/server-admin/dist/"* "$BUILDDIR/usr/lib/fn-knock/server/server-admin/"

# Auth view
cp -r "$SRCDIR/apps/server-auth-view/dist/"* "$BUILDDIR/usr/lib/fn-knock/server-auth-view/dist/"

# Admin view
cp -r "$SRCDIR/apps/server-admin-view/dist/"* "$BUILDDIR/usr/lib/fn-knock/ui/www/"

echo ""
echo "Creating IPK..."

PKG_NAME=$(grep '^Package:' "$BUILDDIR/CONTROL/control" | cut -d' ' -f2-)
PKG_VERSION=$(grep '^Version:' "$BUILDDIR/CONTROL/control" | cut -d' ' -f2-)
IPK_NAME="${PKG_NAME}_${PKG_VERSION}_x86_64.ipk"

cd "$BUILDDIR"
# control.tar.gz must contain files at root level (./control, ./postinst, etc.), NOT under CONTROL/ subdir
cd CONTROL && tar czf /tmp/control.tar.gz . && cd ..
tar czf /tmp/data.tar.gz --hard-dereference --exclude='./CONTROL' .
echo "2.0" > /tmp/debian-binary

rm -f "$OUTDIR/$IPK_NAME"
# IPK = tar.gz containing exactly: debian-binary + control.tar.gz + data.tar.gz (no prefixes)
cd /tmp
tar czf "$OUTDIR/$IPK_NAME" debian-binary control.tar.gz data.tar.gz

# Cleanup
rm -f /tmp/debian-binary /tmp/control.tar.gz /tmp/data.tar.gz

echo ""
echo "=== Build Complete ==="
ls -lh "$OUTDIR/$IPK_NAME"
file "$OUTDIR/$IPK_NAME"
echo "Output: $OUTDIR/$IPK_NAME"
