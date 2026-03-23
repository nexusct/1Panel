#!/bin/bash
# React Bricks CMS Installer
# Scaffolds a new React Bricks project using: npx create-reactbricks-app@latest

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REACTBRICKS_PROJECT_NAME="${REACTBRICKS_PROJECT_NAME:-my-reactbricks-app}"
REACTBRICKS_INSTALL_DIR="${REACTBRICKS_INSTALL_DIR:-/opt/reactbricks}"

log_info()  { echo -e "${BLUE}[React Bricks] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[React Bricks] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[React Bricks] $1${NC}"; }
log_err()   { echo -e "${RED}[React Bricks] $1${NC}"; }

check_node() {
    if ! command -v node >/dev/null 2>&1; then
        log_err "Node.js is required but not found. Please install Node.js 18+ first."
        return 1
    fi
    node_major=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_major" -lt 18 ]; then
        log_err "Node.js 18+ required (found $(node --version))."
        return 1
    fi
    log_ok "Node.js $(node --version) detected."
}

install_react_bricks() {
    log_info "Setting up React Bricks CMS project '${REACTBRICKS_PROJECT_NAME}'..."

    TARGET_DIR="${REACTBRICKS_INSTALL_DIR}/${REACTBRICKS_PROJECT_NAME}"

    if [ -d "${TARGET_DIR}" ]; then
        log_warn "React Bricks project already exists at ${TARGET_DIR}. Skipping."
        return 0
    fi

    mkdir -p "${REACTBRICKS_INSTALL_DIR}"

    log_info "Scaffolding React Bricks project at ${TARGET_DIR} (this may take a few minutes)..."
    cd "${REACTBRICKS_INSTALL_DIR}"

    if npx create-reactbricks-app@latest "${REACTBRICKS_PROJECT_NAME}"; then
        log_ok "React Bricks project '${REACTBRICKS_PROJECT_NAME}' created at ${TARGET_DIR}."
        log_info "  To start: cd ${TARGET_DIR} && npm run dev"
        log_info "  Docs: https://www.reactbricks.com/docs"
        log_info "  npm:  https://www.npmjs.com/package/react-bricks"
        log_info "  Note: You will need a React Bricks account and App ID to use the CMS."
    else
        log_err "Failed to scaffold React Bricks project."
        return 1
    fi
}

check_node && install_react_bricks
