#!/bin/bash
set -euo pipefail

APP_HOME="${TRIM_APPDEST:-}"
PKG_VAR_DIR="${TRIM_PKGVAR:-}"
LOG_FILE="${PKG_VAR_DIR}/info.log"
BACKEND_PID_FILE="${PKG_VAR_DIR}/backend.pid"
GATEWAY_PID_FILE="${PKG_VAR_DIR}/gateway.pid"
ALTCHA_HMAC_KEY_FILE="${PKG_VAR_DIR}/altcha_hmac_key"
GATEWAY_CONFIG_DIR="${PKG_VAR_DIR}/gateway-config"

NODE_BIN_V20="/var/apps/nodejs_v20/target/bin/node"
NODE_BIN_V24="/var/apps/nodejs_v24/target/bin/node"
NODE_BIN="${NODE_BIN:-}"
BACKEND_ENTRY="${APP_HOME}/server/server-admin/index.js"
GATEWAY_BIN_DIR="${APP_HOME}/server"
GATEWAY_BIN="${GATEWAY_BIN_DIR}/go-reauth-proxy-linux-arm64"

ADMIN_STATIC_PATH="${APP_HOME}/ui/www"
AUTH_STATIC_PATH="${APP_HOME}/server-auth-view/dist"
ACME_BUNDLE_ZIP="${APP_HOME}/server/server-admin/resources/acmesh.zip"

BACKEND_PORT="7998"
AUTH_PORT="7997"
GO_BACKEND_PORT="7996"
GO_REPROXY_PORT="7999"
ALTCHA_HMAC_KEY="${ALTCHA_HMAC_KEY:-}"
ROOT_SHARE_DIR="${FN_KNOCK_ROOT_SHARE_DIR:-${FN_KNOCK_CERT_SHARE_DIR:-}}"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${LOG_FILE}"
}

generate_random_hex() {
    local bytes="${1:-32}"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex "${bytes}" 2>/dev/null
        return $?
    fi
    od -An -v -N "${bytes}" -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'
}

resolve_node_bin() {
    local explicit_node_bin="${NODE_BIN:-}"
    if [ -n "${explicit_node_bin}" ] && [ -x "${explicit_node_bin}" ]; then
        NODE_BIN="${explicit_node_bin}"
        log_msg "Using NODE_BIN from environment: ${NODE_BIN}"
        return 0
    fi
    if [ -x "${NODE_BIN_V20}" ]; then
        NODE_BIN="${NODE_BIN_V20}"
        log_msg "Using bundled Node.js runtime: ${NODE_BIN}"
        return 0
    fi
    if [ -x "${NODE_BIN_V24}" ]; then
        NODE_BIN="${NODE_BIN_V24}"
        log_msg "Using bundled Node.js runtime: ${NODE_BIN}"
        return 0
    fi
    NODE_BIN="$(command -v node 2>/dev/null || true)"
    if [ -n "${NODE_BIN}" ] && [ -x "${NODE_BIN}" ]; then
        log_msg "Using Node.js from PATH: ${NODE_BIN}"
        return 0
    fi
    NODE_BIN=""
    return 1
}

ensure_runtime_layout() {
    if [ -z "${PKG_VAR_DIR}" ]; then
        echo "TRIM_PKGVAR is empty; cannot start fn-knock" >&2
        return 1
    fi
    if [ -z "${APP_HOME}" ]; then
        echo "TRIM_APPDEST is empty; cannot start fn-knock" >&2
        return 1
    fi
    mkdir -p "${PKG_VAR_DIR}" "${PKG_VAR_DIR}/frp" "${PKG_VAR_DIR}/cloudflared" "${PKG_VAR_DIR}/updates" "${GATEWAY_CONFIG_DIR}" || true
    return 0
}

start_backend() {
    if [ -f "${BACKEND_PID_FILE}" ]; then
        local old_pid
        old_pid="$(cat "${BACKEND_PID_FILE}" 2>/dev/null || true)"
        if [ -n "${old_pid}" ] && kill -0 "${old_pid}" 2>/dev/null; then
            log_msg "Backend already running (pid=${old_pid})"
            return 0
        fi
    fi

    if [ -z "${ALTCHA_HMAC_KEY}" ]; then
        if [ -f "${ALTCHA_HMAC_KEY_FILE}" ]; then
            ALTCHA_HMAC_KEY="$(cat "${ALTCHA_HMAC_KEY_FILE}")"
        else
            ALTCHA_HMAC_KEY="$(generate_random_hex 32)"
            echo "${ALTCHA_HMAC_KEY}" > "${ALTCHA_HMAC_KEY_FILE}"
        fi
    fi

    local node_env="production"
    local hmac_secret
    hmac_secret="$(generate_random_hex 32)"

    export NODE_ENV="${node_env}"
    export HMAC_SECRET="${hmac_secret}"
    export ALTCHA_HMAC_KEY="${ALTCHA_HMAC_KEY}"
    export BACKEND_PORT="${BACKEND_PORT}"
    export AUTH_PORT="${AUTH_PORT}"
    export GO_BACKEND_PORT="${GO_BACKEND_PORT}"
    export GO_REPROXY_PORT="${GO_REPROXY_PORT}"
    export ADMIN_STATIC_PATH="${ADMIN_STATIC_PATH}"
    export AUTH_STATIC_PATH="${AUTH_STATIC_PATH}"
    export ACME_BUNDLE_ZIP="${ACME_BUNDLE_ZIP}"
    export FN_KNOCK_ROOT_SHARE_DIR="${ROOT_SHARE_DIR}"
    export FN_KNOCK_CERT_SHARE_DIR="${ROOT_SHARE_DIR}"
    export GATEWAY_CONFIG_DIR="${GATEWAY_CONFIG_DIR}"
    export REDIS_URL="redis://127.0.0.1:6379"

    nohup "${NODE_BIN}" "${BACKEND_ENTRY}" >> "${LOG_FILE}" 2>&1 &
    local pid=$!
    echo "${pid}" > "${BACKEND_PID_FILE}"
    log_msg "Backend started (pid=${pid}, port=${BACKEND_PORT})"
}

start_gateway() {
    if [ -f "${GATEWAY_PID_FILE}" ]; then
        local old_pid
        old_pid="$(cat "${GATEWAY_PID_FILE}" 2>/dev/null || true)"
        if [ -n "${old_pid}" ] && kill -0 "${old_pid}" 2>/dev/null; then
            log_msg "Gateway already running (pid=${old_pid})"
            return 0
        fi
    fi

    if [ ! -x "${GATEWAY_BIN}" ]; then
        log_msg "Gateway binary not found or not executable: ${GATEWAY_BIN}"
        return 1
    fi

    nohup "${GATEWAY_BIN}" >> "${LOG_FILE}" 2>&1 &
    local pid=$!
    echo "${pid}" > "${GATEWAY_PID_FILE}"
    log_msg "Gateway started (pid=${pid})"
}

main() {
    ensure_runtime_layout
    resolve_node_bin || {
        log_msg "Node.js runtime not found. Please install nodejs_v24 from App Center."
        return 1
    }
    start_backend
    start_gateway
    log_msg "fn-knock started successfully"
}

main "$@"
