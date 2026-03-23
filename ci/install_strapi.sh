#!/bin/bash
# Strapi CMS Installer
# Scaffolds a new Strapi project using: npx create-strapi@latest

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STRAPI_PROJECT_NAME="${STRAPI_PROJECT_NAME:-my-strapi-app}"
STRAPI_INSTALL_DIR="${STRAPI_INSTALL_DIR:-/opt/strapi}"

log_info()  { echo -e "${BLUE}[Strapi] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[Strapi] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[Strapi] $1${NC}"; }
log_err()   { echo -e "${RED}[Strapi] $1${NC}"; }

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

install_strapi() {
    log_info "Setting up Strapi CMS project '${STRAPI_PROJECT_NAME}'..."

    TARGET_DIR="${STRAPI_INSTALL_DIR}/${STRAPI_PROJECT_NAME}"

    if [ -d "${TARGET_DIR}" ]; then
        log_warn "Strapi project already exists at ${TARGET_DIR}. Skipping."
        return 0
    fi

    mkdir -p "${STRAPI_INSTALL_DIR}"

    log_info "Scaffolding Strapi project at ${TARGET_DIR} (this may take a few minutes)..."
    cd "${STRAPI_INSTALL_DIR}"

    # Use --quickstart for SQLite (no extra DB setup needed)
    if npx create-strapi@latest "${STRAPI_PROJECT_NAME}" --quickstart --no-run; then
        log_ok "Strapi project '${STRAPI_PROJECT_NAME}' created at ${TARGET_DIR}."
        log_info "  To start Strapi: cd ${TARGET_DIR} && npm run develop"
        log_info "  Default port: 1337"
        log_info "  Admin panel: http://localhost:1337/admin"
        log_info "  Docs: https://docs.strapi.io/cms/installation/cli"
    else
        log_err "Failed to scaffold Strapi project."
        return 1
    fi
}

check_node && install_strapi
