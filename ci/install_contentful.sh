#!/bin/bash
# Contentful CLI Installer
# npm package: contentful-cli

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[Contentful CLI] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[Contentful CLI] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[Contentful CLI] $1${NC}"; }
log_err()   { echo -e "${RED}[Contentful CLI] $1${NC}"; }

check_node() {
    if ! command -v node >/dev/null 2>&1; then
        log_err "Node.js is required but not found. Please install Node.js LTS first."
        return 1
    fi
    log_ok "Node.js $(node --version) detected."
}

install_contentful_cli() {
    log_info "Installing Contentful CLI..."

    if command -v contentful >/dev/null 2>&1; then
        log_warn "Contentful CLI already installed ($(contentful --version 2>/dev/null || echo 'unknown')). Skipping."
        return 0
    fi

    if npm install -g contentful-cli; then
        log_ok "Contentful CLI installed successfully."
        log_info "  Run 'contentful login' to authenticate."
        log_info "  Docs: https://www.contentful.com/developers/docs/tutorials/cli/"
        log_info "  npm:  https://www.npmjs.com/package/contentful-cli"
    else
        log_err "Failed to install Contentful CLI."
        return 1
    fi
}

check_node && install_contentful_cli
