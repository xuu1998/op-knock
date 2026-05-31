#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ROOT_DIR = (Get-Item (Join-Path $PSScriptRoot "../../..")).FullName
$APP_DIR = Join-Path $ROOT_DIR "apps/fn-knock-ugreen"
$VERSION_FILE = Join-Path $ROOT_DIR "apps/server-admin/src/lib/app-version.ts"
$PROJECT_FILE = Join-Path $APP_DIR "project.yaml"

function Sync-ProjectVersion {
    if (-not (Test-Path $VERSION_FILE)) {
        Write-Error "[fn-knock-ugreen] Missing version file: $VERSION_FILE"
        exit 1
    }

    $appVersion = (Get-Content $VERSION_FILE -Raw) |
        Select-String -Pattern 'APP_LOCAL_VERSION\s*=\s*"([^"]+)"' |
        ForEach-Object { $_.Matches.Groups[1].Value }

    if (-not $appVersion) {
        Write-Error "[fn-knock-ugreen] Failed to parse APP_LOCAL_VERSION from $VERSION_FILE"
        exit 1
    }

    $currentVersion = (Get-Content $PROJECT_FILE -Raw) |
        Select-String -Pattern '^version:\s*(.+)$' |
        ForEach-Object { $_.Matches.Groups[1].Value.Trim() }

    if ($currentVersion -eq $appVersion) {
        Write-Host "[fn-knock-ugreen] project.yaml version is already up to date: $appVersion"
        return
    }

    $content = Get-Content $PROJECT_FILE -Raw
    $content = $content -replace '^version:\s*.+$', "version: $appVersion"
    Set-Content -Path $PROJECT_FILE -Value $content -NoNewline

    Write-Host "[fn-knock-ugreen] Synced project.yaml version: $currentVersion -> $appVersion"
}

function Build-PackageAssets {
    Push-Location $ROOT_DIR

    Write-Host "[fn-knock-ugreen] Syncing project.yaml version..."
    Sync-ProjectVersion

    $RUNTIME_DIR = Join-Path $ROOT_DIR "dist/fn-knock-runtime"

    Write-Host "[fn-knock-ugreen] Building shared runtime assets..."

    # Build frontend apps
    npx turbo run build --filter=server-admin-view --filter=server-auth-view --force

    # Build server-admin backend
    npm run build --workspace server-admin

    # Prepare runtime directories
    $ADMIN_WWW_DIR = Join-Path $RUNTIME_DIR "ui/www"
    $AUTH_DIST_DIR = Join-Path $RUNTIME_DIR "server-auth-view/dist"
    $SERVER_ADMIN_DIR = Join-Path $RUNTIME_DIR "server/server-admin"
    $SERVER_DIR = Join-Path $RUNTIME_DIR "server"

    New-Item -ItemType Directory -Force -Path $ADMIN_WWW_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $AUTH_DIST_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $SERVER_ADMIN_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $SERVER_DIR | Out-Null

    # Sync built assets
    $SRC_ADMIN_WWW = Join-Path $ROOT_DIR "apps/server-admin-view/dist"
    $SRC_AUTH_DIST = Join-Path $ROOT_DIR "apps/server-auth-view/dist"
    $SRC_SERVER_ADMIN = Join-Path $ROOT_DIR "apps/server-admin/dist"

    Write-Host "[fn-knock-ugreen] Syncing server-admin-view dist -> runtime/ui/www"
    robocopy "$SRC_ADMIN_WWW" "$ADMIN_WWW_DIR" /MIR /NFL /NDL /NJH /NJS

    Write-Host "[fn-knock-ugreen] Syncing server-auth-view dist -> runtime/server-auth-view/dist"
    robocopy "$SRC_AUTH_DIST" "$AUTH_DIST_DIR" /MIR /NFL /NDL /NJH /NJS

    Write-Host "[fn-knock-ugreen] Syncing server-admin dist -> runtime/server/server-admin"
    robocopy "$SRC_SERVER_ADMIN" "$SERVER_ADMIN_DIR" /MIR /NFL /NDL /NJH /NJS

    # Copy acme resource
    $ACME_SRC = Join-Path $ROOT_DIR "apps/server-admin/resources/acmesh.zip"
    if (Test-Path $ACME_SRC) {
        $RES_DIR = Join-Path $SERVER_ADMIN_DIR "resources"
        New-Item -ItemType Directory -Force -Path $RES_DIR | Out-Null
        Copy-Item $ACME_SRC (Join-Path $RES_DIR "acmesh.zip") -Force
    }

    # Sync to package directories
    $PKG_WWW_DIR = Join-Path $APP_DIR "rootfs_common/www"
    $PKG_AUTH_DIR = Join-Path $APP_DIR "rootfs_common/server-auth-view/dist"
    $PKG_SERVER_ADMIN_DIR = Join-Path $APP_DIR "rootfs_common/server/server-admin"
    $PKG_SERVER_DIR = Join-Path $APP_DIR "rootfs_common/server"

    New-Item -ItemType Directory -Force -Path $PKG_WWW_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $PKG_AUTH_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $PKG_SERVER_ADMIN_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $PKG_SERVER_DIR | Out-Null

    Write-Host "[fn-knock-ugreen] Syncing runtime -> package rootfs_common"
    robocopy "$ADMIN_WWW_DIR" "$PKG_WWW_DIR" /MIR /NFL /NDL /NJH /NJS
    robocopy "$AUTH_DIST_DIR" "$PKG_AUTH_DIR" /MIR /NFL /NDL /NJH /NJS
    robocopy "$SERVER_ADMIN_DIR" "$PKG_SERVER_ADMIN_DIR" /MIR /NFL /NDL /NJH /NJS

    # Gateway binaries placeholder (user needs to provide or build separately)
    $GATEWAY_AMD64 = Join-Path $PKG_SERVER_DIR "go-reauth-proxy-linux-amd64"
    $GATEWAY_ARM64 = Join-Path $PKG_SERVER_DIR "go-reauth-proxy-linux-arm64"

    if (-not (Test-Path $GATEWAY_AMD64)) {
        Write-Warning "[fn-knock-ugreen] Missing gateway binary: go-reauth-proxy-linux-amd64"
        Write-Warning "[fn-knock-ugreen] Please build Go-Reauth-Proxy and place binaries in $PKG_SERVER_DIR"
    }
    if (-not (Test-Path $GATEWAY_ARM64)) {
        Write-Warning "[fn-knock-ugreen] Missing gateway binary: go-reauth-proxy-linux-arm64"
        Write-Warning "[fn-knock-ugreen] Please build Go-Reauth-Proxy and place binaries in $PKG_SERVER_DIR"
    }

    # Make scripts executable (for WSL/Git Bash compatibility)
    $START_AMD64 = Join-Path $APP_DIR "rootfs_amd64/bin/fn-knock-start.sh"
    $START_ARM64 = Join-Path $APP_DIR "rootfs_arm64/bin/fn-knock-start.sh"

    Write-Host "[fn-knock-ugreen] Package assets are ready under $APP_DIR"
    Write-Host ""
    Write-Host "=== Next Steps ==="
    Write-Host "1. Build or obtain go-reauth-proxy binaries for amd64 and arm64"
    Write-Host "2. Place them in: $PKG_SERVER_DIR"
    Write-Host "3. Install ugcli tool (Linux environment)"
    Write-Host "4. Run: ugcli check && ugcli pack --arch all --build 1"
    Write-Host ""

    Pop-Location
}

# Main
Build-PackageAssets
