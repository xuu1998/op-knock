#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/fn-knock-ugreen"
VERSION_FILE="${ROOT_DIR}/apps/server-admin/src/lib/app-version.ts"
PROJECT_FILE="${APP_DIR}/project.yaml"

sync_project_version() {
  if [ ! -f "${VERSION_FILE}" ]; then
    echo "[fn-knock-ugreen] Missing version file: ${VERSION_FILE}" >&2
    exit 1
  fi

  local app_version
  app_version="$(sed -nE 's/^[[:space:]]*export[[:space:]]+const[[:space:]]+APP_LOCAL_VERSION[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "${VERSION_FILE}" | head -n1)"
  if [ -z "${app_version}" ]; then
    echo "[fn-knock-ugreen] Failed to parse APP_LOCAL_VERSION from ${VERSION_FILE}" >&2
    exit 1
  fi

  local current_version
  current_version="$(sed -nE 's/^version:[[:space:]]*(.*)$/\1/p' "${PROJECT_FILE}" | head -n1)"

  if [ "${current_version}" = "${app_version}" ]; then
    echo "[fn-knock-ugreen] project.yaml version is already up to date: ${app_version}"
    return 0
  fi

  local tmp_project
  tmp_project="$(mktemp)"
  awk -v version="${app_version}" '
    BEGIN { updated = 0 }
    /^version:[[:space:]]*/ {
      print "version: " version
      updated = 1
      next
    }
    { print }
    END {
      if (!updated) {
        print "version: " version
      }
    }
  ' "${PROJECT_FILE}" > "${tmp_project}"
  mv "${tmp_project}" "${PROJECT_FILE}"

  echo "[fn-knock-ugreen] Synced project.yaml version: ${current_version:-<empty>} -> ${app_version}"
}

build_package_assets() {
  cd "${ROOT_DIR}"

  echo "[fn-knock-ugreen] Syncing project.yaml version from server-admin app version..."
  sync_project_version

  RUNTIME_DIR="${ROOT_DIR}/dist/fn-knock-runtime"

  echo "[fn-knock-ugreen] Building shared runtime assets..."
  bash "${ROOT_DIR}/scripts/assemble-runtime.sh" "${RUNTIME_DIR}"

  WWW_DIR="${APP_DIR}/rootfs_common/www"
  AUTH_DIST_DIR="${APP_DIR}/rootfs_common/server-auth-view/dist"
  SERVER_ADMIN_DIR="${APP_DIR}/rootfs_common/server/server-admin"
  SERVER_DIR="${APP_DIR}/rootfs_common/server"

  echo "[fn-knock-ugreen] Preparing package directories..."
  mkdir -p "${WWW_DIR}" "${AUTH_DIST_DIR}" "${SERVER_ADMIN_DIR}" "${SERVER_DIR}"

  echo "[fn-knock-ugreen] Syncing server-admin-view dist -> rootfs_common/www"
  rsync -a --delete "${RUNTIME_DIR}/ui/www/" "${WWW_DIR}/"

  echo "[fn-knock-ugreen] Syncing server-auth-view dist -> rootfs_common/server-auth-view/dist"
  rsync -a --delete "${RUNTIME_DIR}/server-auth-view/dist/" "${AUTH_DIST_DIR}/"

  echo "[fn-knock-ugreen] Syncing server-admin dist -> rootfs_common/server/server-admin"
  rsync -a --delete "${RUNTIME_DIR}/server/server-admin/" "${SERVER_ADMIN_DIR}/"

  echo "[fn-knock-ugreen] Copying gateway binaries"
  cp "${RUNTIME_DIR}/server/go-reauth-proxy-linux-amd64" "${SERVER_DIR}/go-reauth-proxy-linux-amd64"
  cp "${RUNTIME_DIR}/server/go-reauth-proxy-linux-arm64" "${SERVER_DIR}/go-reauth-proxy-linux-arm64"

  chmod +x \
    "${APP_DIR}/rootfs_amd64/bin/fn-knock-start.sh" \
    "${APP_DIR}/rootfs_arm64/bin/fn-knock-start.sh" \
    "${SERVER_DIR}/go-reauth-proxy-linux-amd64" \
    "${SERVER_DIR}/go-reauth-proxy-linux-arm64"

  echo "[fn-knock-ugreen] Package assets are ready under ${APP_DIR}"
}

usage() {
  cat <<'EOF'
Usage:
  ./apps/fn-knock-ugreen/scripts/build-package.sh [build-assets]

Commands:
  build-assets  Build and sync package assets (default)
EOF
}

cmd="${1:-build-assets}"
case "${cmd}" in
  build-assets)
    build_package_assets
    ;;
  *)
    usage
    exit 1
    ;;
esac
